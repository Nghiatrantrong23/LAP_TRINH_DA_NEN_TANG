using System.Security.Claims;
using System.Text.Json;
using Google.Apis.Auth;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using WebApi.Models;
using WebApi.Services;

namespace WebApi.Api.Controllers;

[ApiController, Route("api/[controller]")]
public class AuthController : BaseController
{
    private readonly IEmailService _emailService;
    private readonly IConfiguration _config;

    public AuthController(IEmailService emailService, IConfiguration config)
    {
        _emailService = emailService;
        _config = config;
    }

    // 1. Đăng ký tài khoản (0.25đ) + Tạo mã OTP xác thực email (0.5đ)
    [HttpPost("register")]
    public async Task<IActionResult> Register(RegisterModel obj)
    {
        if (!ModelState.IsValid) return BadRequest(new { code = -2, message = "Dữ liệu không hợp lệ" });

        var (code, otp) = Provider.ThanhVien.Register(obj);
        if (code == -1)
            return BadRequest(new { code = -1, message = "Email này đã được sử dụng trong hệ thống" });

        if (code > 0 && !string.IsNullOrEmpty(otp))
        {
            string emailBody = $@"
                <div style='font-family: Arial, sans-serif; padding: 20px;'>
                    <h2 style='color: #2E7D32;'>Chào mừng bạn đến với Đặt Sân Thể Thao!</h2>
                    <p>Mã xác thực tài khoản (OTP) của bạn là:</p>
                    <h1 style='color: #1976D2; letter-spacing: 5px;'>{otp}</h1>
                    <p>Mã này có hiệu lực trong 15 phút. Vui lòng không chia sẻ mã này cho bất kỳ ai.</p>
                </div>";
            await _emailService.SendEmailAsync(obj.Email, "Xác thực tài khoản Đặt Sân Thể Thao", emailBody);
            return Ok(new { code = 1, message = "Đăng ký thành công! Vui lòng kiểm tra email để lấy mã OTP xác thực tài khoản." });
        }

        return StatusCode(500, new { code = -2, message = "Đăng ký thất bại, vui lòng thử lại sau" });
    }

    // 2. Xác thực tài khoản qua Email OTP (0.5đ điểm cộng)
    [HttpPost("verify-email")]
    public IActionResult VerifyEmail(VerifyEmailModel obj)
    {
        if (!ModelState.IsValid) return BadRequest(new { code = -2, message = "Dữ liệu không hợp lệ" });

        int ret = Provider.ThanhVien.VerifyEmail(obj.Email, obj.Code);
        if (ret == -1) return NotFound(new { code = -1, message = "Email không tồn tại" });
        if (ret == -2) return BadRequest(new { code = -2, message = "Mã xác thực OTP không đúng hoặc đã hết hạn" });
        if (ret == -3) return BadRequest(new { code = -3, message = "Bạn đã nhập sai mã quá 5 lần. Vui lòng yêu cầu mã mới." });

        return Ok(new { code = 1, message = "Xác thực tài khoản thành công! Bạn có thể đăng nhập ngay bây giờ." });
    }

    // Gửi lại mã OTP
    [HttpPost("resend-code")]
    public async Task<IActionResult> ResendCode([FromBody] string email)
    {
        var (code, otp) = Provider.ThanhVien.ResendConfirmationCode(email);
        if (code == -1) return NotFound(new { code = -1, message = "Email không tồn tại" });
        if (code == -3) return BadRequest(new { code = -3, message = "Tài khoản này đã được xác thực trước đó" });

        if (code > 0 && !string.IsNullOrEmpty(otp))
        {
            string emailBody = $"<p>Mã xác thực mới của bạn là: <b>{otp}</b> (hiệu lực 15 phút).</p>";
            await _emailService.SendEmailAsync(email, "Mã xác thực tài khoản mới", emailBody);
            return Ok(new { code = 1, message = "Đã gửi lại mã OTP vào email của bạn" });
        }

        return StatusCode(500, new { code = -2, message = "Không thể gửi lại mã OTP lúc này" });
    }

    // 3. Đăng nhập hệ thống (0.25đ)
    [HttpPost("login")]
    public IActionResult Login(LoginModel obj)
    {
        if (!ModelState.IsValid) return BadRequest(new { success = false, message = "Dữ liệu không hợp lệ" });

        LoginResponse result = Provider.ThanhVien.Login(obj, _config);
        if (result.Success)
        {
            return Ok(result);
        }
        return Unauthorized(result);
    }

    // 4.1. ĐĂNG NHẬP GOOGLE THẬT QUA ID_TOKEN (0.5đ)
    [HttpPost("google-login")]
    public async Task<IActionResult> GoogleLogin([FromBody] SocialTokenLoginModel obj)
    {
        try
        {
            var settings = new GoogleJsonWebSignature.ValidationSettings();
            string? expectedAudience = _config["OAuth:Google:ClientId"];
            if (!string.IsNullOrEmpty(expectedAudience) && !expectedAudience.Contains("your-"))
            {
                settings.Audience = new[] { expectedAudience };
            }

            // Xác thực token trực tiếp với máy chủ Google
            var payload = await GoogleJsonWebSignature.ValidateAsync(obj.Token, settings);
            if (payload != null && !string.IsNullOrEmpty(payload.Email))
            {
                var loginModel = new ExternalLoginModel
                {
                    Provider = "Google",
                    ProviderKey = payload.Subject,
                    Email = payload.Email,
                    FullName = payload.Name ?? payload.Email
                };
                LoginResponse result = Provider.ThanhVien.ExternalLogin(loginModel, _config);
                return Ok(result);
            }
            return Unauthorized(new { success = false, message = "Xác thực Google ID Token không thành công" });
        }
        catch (Exception ex)
        {
            return BadRequest(new { success = false, message = $"Lỗi xác thực Google: {ex.Message}" });
        }
    }

    // 4.2. ĐĂNG NHẬP FACEBOOK THẬT QUA ACCESS_TOKEN (0.5đ)
    [HttpPost("facebook-login")]
    public async Task<IActionResult> FacebookLogin([FromBody] SocialTokenLoginModel obj)
    {
        try
        {
            using var client = new HttpClient();
            string url = $"https://graph.facebook.com/me?fields=id,name,email&access_token={obj.Token}";
            var response = await client.GetAsync(url);
            if (response.IsSuccessStatusCode)
            {
                var json = await response.Content.ReadAsStringAsync();
                using var doc = JsonDocument.Parse(json);
                var root = doc.RootElement;
                string fbId = root.GetProperty("id").GetString()!;
                string name = root.TryGetProperty("name", out var n) ? n.GetString()! : "Facebook User";
                string email = root.TryGetProperty("email", out var e) ? e.GetString()! : $"{fbId}@facebook.com";

                var loginModel = new ExternalLoginModel
                {
                    Provider = "Facebook",
                    ProviderKey = fbId,
                    Email = email,
                    FullName = name
                };
                LoginResponse result = Provider.ThanhVien.ExternalLogin(loginModel, _config);
                return Ok(result);
            }
            return Unauthorized(new { success = false, message = "Access Token Facebook không hợp lệ" });
        }
        catch (Exception ex)
        {
            return BadRequest(new { success = false, message = $"Lỗi xác thực Facebook: {ex.Message}" });
        }
    }

    // 4.3. ĐĂNG NHẬP ZALO THẬT QUA ACCESS_TOKEN (0.5đ)
    [HttpPost("zalo-login")]
    public async Task<IActionResult> ZaloLogin([FromBody] SocialTokenLoginModel obj)
    {
        try
        {
            using var client = new HttpClient();
            client.DefaultRequestHeaders.Add("access_token", obj.Token);
            var response = await client.GetAsync("https://graph.zalo.me/v2.0/me?fields=id,name,picture");
            if (response.IsSuccessStatusCode)
            {
                var json = await response.Content.ReadAsStringAsync();
                using var doc = JsonDocument.Parse(json);
                var root = doc.RootElement;
                if (root.TryGetProperty("id", out var idElem))
                {
                    string zaloId = idElem.GetString()!;
                    string name = root.TryGetProperty("name", out var n) ? n.GetString()! : "Zalo User";
                    string email = $"{zaloId}@zalo.me";

                    var loginModel = new ExternalLoginModel
                    {
                        Provider = "Zalo",
                        ProviderKey = zaloId,
                        Email = email,
                        FullName = name
                    };
                    LoginResponse result = Provider.ThanhVien.ExternalLogin(loginModel, _config);
                    return Ok(result);
                }
            }
            return Unauthorized(new { success = false, message = "Access Token Zalo không hợp lệ" });
        }
        catch (Exception ex)
        {
            return BadRequest(new { success = false, message = $"Lỗi xác thực Zalo: {ex.Message}" });
        }
    }

    // 4.4. Đăng nhập liên kết mạng xã hội (Hỗ trợ cả Mock & API tích hợp)
    [HttpPost("external-login")]
    public IActionResult ExternalLogin(ExternalLoginModel obj)
    {
        if (!ModelState.IsValid) return BadRequest(new { success = false, message = "Dữ liệu đăng nhập bên thứ 3 không hợp lệ" });

        LoginResponse result = Provider.ThanhVien.ExternalLogin(obj, _config);
        if (result.Success)
        {
            return Ok(result);
        }
        return BadRequest(result);
    }

    // 5. Quên mật khẩu (0.5đ điểm cộng)
    [HttpPost("forgot-password")]
    public async Task<IActionResult> ForgotPassword(ForgotPasswordModel obj)
    {
        var (code, otp) = Provider.ThanhVien.ForgotPassword(obj.Email);
        if (code == -1) return NotFound(new { code = -1, message = "Email này không tồn tại trong hệ thống" });

        if (code > 0 && !string.IsNullOrEmpty(otp))
        {
            string emailBody = $@"
                <div style='font-family: Arial, sans-serif; padding: 20px;'>
                    <h2 style='color: #D32F2F;'>Yêu cầu đặt lại mật khẩu</h2>
                    <p>Mã xác thực để đặt lại mật khẩu của bạn là:</p>
                    <h1 style='color: #D32F2F; letter-spacing: 5px;'>{otp}</h1>
                    <p>Mã này có hiệu lực trong 15 phút. Nếu bạn không gửi yêu cầu này, vui lòng bỏ qua email.</p>
                </div>";
            await _emailService.SendEmailAsync(obj.Email, "Đặt lại mật khẩu - Đặt Sân Thể Thao", emailBody);
            return Ok(new { code = 1, message = "Đã gửi mã OTP đặt lại mật khẩu đến email của bạn" });
        }

        return StatusCode(500, new { code = -2, message = "Không thể xử lý yêu cầu lúc này" });
    }

    // Đặt lại mật khẩu với OTP
    [HttpPost("reset-password")]
    public IActionResult ResetPassword(ResetPasswordModel obj)
    {
        int ret = Provider.ThanhVien.ResetPassword(obj);
        if (ret == -1) return NotFound(new { code = -1, message = "Email không tồn tại" });
        if (ret == -2) return BadRequest(new { code = -2, message = "Mã OTP không hợp lệ hoặc đã hết hạn" });

        return Ok(new { code = 1, message = "Mật khẩu đã được đặt lại thành công! Bạn có thể đăng nhập bằng mật khẩu mới." });
    }

    // 6. Đổi mật khẩu (0.25đ)
    [Authorize, HttpPost("change-password")]
    public IActionResult ChangePassword(ChangePasswordModel obj)
    {
        string? memberIdStr = User.FindFirstValue(ClaimTypes.NameIdentifier);
        if (string.IsNullOrEmpty(memberIdStr) || !Guid.TryParse(memberIdStr, out Guid memberId))
            return Unauthorized();

        int ret = Provider.ThanhVien.ChangePassword(memberId, obj);
        if (ret == -1) return NotFound(new { code = -1, message = "Người dùng không tồn tại" });
        if (ret == -2) return BadRequest(new { code = -2, message = "Mật khẩu cũ không chính xác" });

        return Ok(new { code = 1, message = "Đổi mật khẩu thành công!" });
    }

    // 7. Lấy thông tin cá nhân
    [Authorize, HttpGet("profile")]
    public IActionResult GetProfile()
    {
        string? memberIdStr = User.FindFirstValue(ClaimTypes.NameIdentifier);
        if (string.IsNullOrEmpty(memberIdStr) || !Guid.TryParse(memberIdStr, out Guid memberId))
            return Unauthorized();

        ThanhVien? member = Provider.ThanhVien.GetMember(memberId);
        if (member is null) return NotFound();

        return Ok(new
        {
            MemberId = member.MaThanhVien.ToString(),
            member.Email,
            GivenName = member.Ten,
            Surname = member.Ho,
            Phone = member.SoDienThoai,
            Role = member.VaiTro?.TenVaiTro,
            RoleId = member.MaVaiTro,
            IsEmailConfirmed = member.DaXacThucEmail,
            IsActive = !member.BiKhoa,
            member.NgayTao
        });
    }

    // Cập nhật thông tin cá nhân
    [Authorize, HttpPut("profile")]
    public IActionResult UpdateProfile(UpdateProfileModel obj)
    {
        string? memberIdStr = User.FindFirstValue(ClaimTypes.NameIdentifier);
        if (string.IsNullOrEmpty(memberIdStr) || !Guid.TryParse(memberIdStr, out Guid memberId))
            return Unauthorized();

        int ret = Provider.ThanhVien.UpdateProfile(memberId, obj);
        return Ok(new { code = ret, message = ret > 0 ? "Cập nhật thông tin thành công" : "Cập nhật thất bại" });
    }
}
