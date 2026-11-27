using System.Collections.Concurrent;
using System.Net.Http.Headers;
using System.Text.Json;
using Microsoft.AspNetCore.Mvc;
using WebApi.Models;

namespace WebApi.Api.Controller;

[ApiController, Route("api/auth/oauth")]
public class OAuthController : BaseController
{
    private record OAuthPollState(string Status, LoginResponse? LoginResponse = null, string? ErrorMessage = null, DateTime? CreatedAt = null);

    private static readonly ConcurrentDictionary<string, OAuthPollState> PendingStates = new();

    private static void CleanupOldStates()
    {
        var cutoff = DateTime.UtcNow.AddMinutes(-10);
        foreach (var kv in PendingStates)
        {
            if (kv.Value.CreatedAt is null || kv.Value.CreatedAt < cutoff)
            {
                PendingStates.TryRemove(kv.Key, out _);
            }
        }
    }

    [HttpGet("{provider}/start")]
    public IActionResult Start(string provider, [FromQuery] string state, [FromServices] IConfiguration config)
    {
        CleanupOldStates();
        if (string.IsNullOrWhiteSpace(state))
        {
            return BadRequest("Missing state.");
        }

        var key = provider.Trim().ToLowerInvariant();
        var redirectUri = $"{Request.Scheme}://{Request.Host}/api/auth/oauth/{key}/callback";

        string? clientId;
        string authUrl;
        string configHint;

        switch (key)
        {
            case "google":
                clientId = config["OAuth:Google:ClientId"];
                configHint = "OAuth:Google:ClientId & OAuth:Google:ClientSecret";
                authUrl = $"https://accounts.google.com/o/oauth2/v2/auth?client_id={Uri.EscapeDataString(clientId ?? "")}&redirect_uri={Uri.EscapeDataString(redirectUri)}&response_type=code&scope={Uri.EscapeDataString("openid email profile")}&state={Uri.EscapeDataString(state)}&prompt=select_account";
                break;

            case "facebook":
                clientId = config["OAuth:Facebook:AppId"];
                configHint = "OAuth:Facebook:AppId & OAuth:Facebook:AppSecret";
                authUrl = $"https://www.facebook.com/v18.0/dialog/oauth?client_id={Uri.EscapeDataString(clientId ?? "")}&redirect_uri={Uri.EscapeDataString(redirectUri)}&response_type=code&scope={Uri.EscapeDataString("email,public_profile")}&state={Uri.EscapeDataString(state)}";
                break;

            case "zalo":
                clientId = config["OAuth:Zalo:AppId"];
                configHint = "OAuth:Zalo:AppId & OAuth:Zalo:AppSecret";
                authUrl = $"https://oauth.zaloapp.com/v4/permission?app_id={Uri.EscapeDataString(clientId ?? "")}&redirect_uri={Uri.EscapeDataString(redirectUri)}&state={Uri.EscapeDataString(state)}";
                break;

            default:
                return BadRequest("Unsupported OAuth provider.");
        }

        if (string.IsNullOrWhiteSpace(clientId))
        {
            var errMsg = $"Chưa cấu hình {configHint} trong WebApi/appsettings.Development.json.";
            PendingStates[state] = new OAuthPollState("error", ErrorMessage: errMsg, CreatedAt: DateTime.UtcNow);
            return Content(BuildHtml("Chưa cấu hình OAuth thật",
                $"<p>{System.Net.WebUtility.HtmlEncode(errMsg)}</p>" +
                $"<p>Redirect URI cần đăng ký: <code>{System.Net.WebUtility.HtmlEncode(redirectUri)}</code></p>" +
                "<p>Sau khi điền khóa vào <code>appsettings.Development.json</code> và khởi động lại WebApi, bạn có thể đăng nhập bằng tài khoản thật.</p>"),
                "text/html; charset=utf-8");
        }

        PendingStates[state] = new OAuthPollState("pending", CreatedAt: DateTime.UtcNow);
        return Redirect(authUrl);
    }

    [HttpGet("{provider}/callback")]
    public async Task<IActionResult> Callback(
        string provider,
        [FromQuery] string? code,
        [FromQuery] string? state,
        [FromQuery] string? error,
        [FromServices] IConfiguration config,
        [FromServices] IHttpClientFactory httpClientFactory)
    {
        if (string.IsNullOrWhiteSpace(state))
        {
            return Content(BuildHtml("Lỗi đăng nhập", "<p>Thiếu tham số state.</p>"), "text/html; charset=utf-8");
        }

        if (!string.IsNullOrWhiteSpace(error) || string.IsNullOrWhiteSpace(code))
        {
            var msg = $"Đăng nhập {provider} bị hủy hoặc lỗi ({error ?? "no_code"}).";
            PendingStates[state] = new OAuthPollState("error", ErrorMessage: msg, CreatedAt: DateTime.UtcNow);
            return Content(BuildHtml("Đăng nhập thất bại", $"<p>{System.Net.WebUtility.HtmlEncode(msg)}</p>"), "text/html; charset=utf-8");
        }

        var key = provider.Trim().ToLowerInvariant();
        var redirectUri = $"{Request.Scheme}://{Request.Host}/api/auth/oauth/{key}/callback";
        var http = httpClientFactory.CreateClient();

        try
        {
            string email;
            string givenName;
            string surname = "";

            switch (key)
            {
                case "google":
                {
                    var clientId = config["OAuth:Google:ClientId"] ?? "";
                    var clientSecret = config["OAuth:Google:ClientSecret"] ?? "";
                    using var tokenReq = new FormUrlEncodedContent(new Dictionary<string, string>
                    {
                        ["code"] = code,
                        ["client_id"] = clientId,
                        ["client_secret"] = clientSecret,
                        ["redirect_uri"] = redirectUri,
                        ["grant_type"] = "authorization_code"
                    });
                    var tokenRes = await http.PostAsync("https://oauth2.googleapis.com/token", tokenReq);
                    var tokenJson = await tokenRes.Content.ReadAsStringAsync();
                    if (!tokenRes.IsSuccessStatusCode)
                    {
                        throw new Exception($"Google token error: {tokenJson}");
                    }
                    using var tokenDoc = JsonDocument.Parse(tokenJson);
                    var accessToken = tokenDoc.RootElement.GetProperty("access_token").GetString()!;

                    using var userReq = new HttpRequestMessage(HttpMethod.Get, "https://www.googleapis.com/oauth2/v3/userinfo");
                    userReq.Headers.Authorization = new AuthenticationHeaderValue("Bearer", accessToken);
                    var userRes = await http.SendAsync(userReq);
                    var userJson = await userRes.Content.ReadAsStringAsync();
                    if (!userRes.IsSuccessStatusCode)
                    {
                        throw new Exception($"Google userinfo error: {userJson}");
                    }
                    using var userDoc = JsonDocument.Parse(userJson);
                    var root = userDoc.RootElement;
                    email = root.GetProperty("email").GetString()!;
                    givenName = root.TryGetProperty("given_name", out var gn) ? gn.GetString() ?? "" : "";
                    surname = root.TryGetProperty("family_name", out var fn) ? fn.GetString() ?? "" : "";
                    if (string.IsNullOrWhiteSpace(givenName) && root.TryGetProperty("name", out var n))
                    {
                        givenName = n.GetString() ?? email;
                    }
                    break;
                }

                case "facebook":
                {
                    var appId = config["OAuth:Facebook:AppId"] ?? "";
                    var appSecret = config["OAuth:Facebook:AppSecret"] ?? "";
                    var tokenUrl = $"https://graph.facebook.com/v18.0/oauth/access_token?client_id={Uri.EscapeDataString(appId)}&redirect_uri={Uri.EscapeDataString(redirectUri)}&client_secret={Uri.EscapeDataString(appSecret)}&code={Uri.EscapeDataString(code)}";
                    var tokenRes = await http.GetAsync(tokenUrl);
                    var tokenJson = await tokenRes.Content.ReadAsStringAsync();
                    if (!tokenRes.IsSuccessStatusCode)
                    {
                        throw new Exception($"Facebook token error: {tokenJson}");
                    }
                    using var tokenDoc = JsonDocument.Parse(tokenJson);
                    var accessToken = tokenDoc.RootElement.GetProperty("access_token").GetString()!;

                    var userUrl = $"https://graph.facebook.com/v18.0/me?fields=id,name,email,first_name,last_name&access_token={Uri.EscapeDataString(accessToken)}";
                    var userRes = await http.GetAsync(userUrl);
                    var userJson = await userRes.Content.ReadAsStringAsync();
                    if (!userRes.IsSuccessStatusCode)
                    {
                        throw new Exception($"Facebook userinfo error: {userJson}");
                    }
                    using var userDoc = JsonDocument.Parse(userJson);
                    var root = userDoc.RootElement;
                    var fbId = root.GetProperty("id").GetString()!;
                    email = root.TryGetProperty("email", out var em) && !string.IsNullOrWhiteSpace(em.GetString())
                        ? em.GetString()!
                        : $"fb_{fbId}@facebook.sportbooking.local";
                    givenName = root.TryGetProperty("first_name", out var fn) ? fn.GetString() ?? "" : "";
                    surname = root.TryGetProperty("last_name", out var ln) ? ln.GetString() ?? "" : "";
                    if (string.IsNullOrWhiteSpace(givenName) && root.TryGetProperty("name", out var n))
                    {
                        givenName = n.GetString() ?? "Facebook User";
                    }
                    break;
                }

                case "zalo":
                {
                    var appId = config["OAuth:Zalo:AppId"] ?? "";
                    var appSecret = config["OAuth:Zalo:AppSecret"] ?? "";
                    using var req = new HttpRequestMessage(HttpMethod.Post, "https://oauth.zaloapp.com/v4/access_token");
                    req.Headers.Add("secret_key", appSecret);
                    req.Content = new FormUrlEncodedContent(new Dictionary<string, string>
                    {
                        ["code"] = code,
                        ["app_id"] = appId,
                        ["grant_type"] = "authorization_code"
                    });
                    var tokenRes = await http.SendAsync(req);
                    var tokenJson = await tokenRes.Content.ReadAsStringAsync();
                    if (!tokenRes.IsSuccessStatusCode)
                    {
                        throw new Exception($"Zalo token error: {tokenJson}");
                    }
                    using var tokenDoc = JsonDocument.Parse(tokenJson);
                    var accessToken = tokenDoc.RootElement.GetProperty("access_token").GetString()!;

                    using var userReq = new HttpRequestMessage(HttpMethod.Get, "https://graph.zalo.me/v2.0/me?fields=id,name");
                    userReq.Headers.Add("access_token", accessToken);
                    var userRes = await http.SendAsync(userReq);
                    var userJson = await userRes.Content.ReadAsStringAsync();
                    if (!userRes.IsSuccessStatusCode)
                    {
                        throw new Exception($"Zalo userinfo error: {userJson}");
                    }
                    using var userDoc = JsonDocument.Parse(userJson);
                    var root = userDoc.RootElement;
                    var zaloId = root.GetProperty("id").GetString()!;
                    email = $"zalo_{zaloId}@zalo.sportbooking.local";
                    givenName = root.TryGetProperty("name", out var n) ? n.GetString() ?? "Zalo User" : "Zalo User";
                    break;
                }

                default:
                    throw new Exception("Unsupported OAuth provider.");
            }

            var loginResponse = await Provider.Auth.UpsertExternalMemberAsync(email, givenName, surname);
            PendingStates[state] = new OAuthPollState("success", LoginResponse: loginResponse, CreatedAt: DateTime.UtcNow);

            return Content(BuildHtml("Đăng nhập thành công!",
                $"<p>Chào mừng <strong>{System.Net.WebUtility.HtmlEncode(givenName)}</strong> ({System.Net.WebUtility.HtmlEncode(email)}).</p>" +
                "<p>Bạn có thể đóng tab trình duyệt này và quay lại ứng dụng SportBooking.</p>"),
                "text/html; charset=utf-8");
        }
        catch (Exception ex)
        {
            PendingStates[state] = new OAuthPollState("error", ErrorMessage: ex.Message, CreatedAt: DateTime.UtcNow);
            return Content(BuildHtml("Lỗi xác thực", $"<p>{System.Net.WebUtility.HtmlEncode(ex.Message)}</p>"), "text/html; charset=utf-8");
        }
    }

    [HttpGet("poll")]
    public IActionResult Poll([FromQuery] string state)
    {
        if (string.IsNullOrWhiteSpace(state) || !PendingStates.TryGetValue(state, out var entry))
        {
            return Ok(new { status = "pending" });
        }

        if (entry.Status == "success")
        {
            PendingStates.TryRemove(state, out _);
            return Ok(new { status = "success", loginResponse = entry.LoginResponse });
        }

        if (entry.Status == "error")
        {
            PendingStates.TryRemove(state, out _);
            return Ok(new { status = "error", message = entry.ErrorMessage });
        }

        return Ok(new { status = "pending" });
    }

    private static string BuildHtml(string title, string body) => $$"""
        <!DOCTYPE html>
        <html lang="vi">
        <head>
          <meta charset="utf-8">
          <title>{{System.Net.WebUtility.HtmlEncode(title)}} - SportBooking</title>
          <style>
            body { font-family: sans-serif; max-width: 520px; margin: 60px auto; padding: 24px; border: 1px solid #ddd; border-radius: 8px; }
            h2 { color: #176448; }
            code { background: #f4f4f4; padding: 2px 6px; border-radius: 4px; }
          </style>
        </head>
        <body>
          <h2>{{System.Net.WebUtility.HtmlEncode(title)}}</h2>
          {{body}}
        </body>
        </html>
        """;
}
