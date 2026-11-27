using System.Security.Claims;
using System.Text;
using System.Threading.RateLimiting;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.RateLimiting;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using WebApi.Models;
using WebApi.Services;
var builder = WebApplication.CreateBuilder(args);
var secret = builder.Configuration["Jwt:SecretKey"];
if (string.IsNullOrWhiteSpace(secret) || Encoding.UTF8.GetByteCount(secret) < 32)
{
    throw new InvalidOperationException("Set Jwt:SecretKey to a private value of at least 32 bytes.");
}

builder.Services.AddDbContext<SportsBookingContext>(o => o.UseSqlServer(builder.Configuration.GetConnectionString("SportsBooking")));
builder.Services.AddHttpContextAccessor();
builder.Services.AddHttpClient();
builder.Services.AddScoped<SiteProvider>();
builder.Services.AddScoped<IEmailService, EmailService>();
builder.Services.AddControllers();
builder.Services.AddSingleton<FileStorage>();
builder.Services.AddHostedService<FileCleanupWorker>();
builder.Services.AddCors(o => o.AddDefaultPolicy(p => p.WithOrigins(builder.Configuration.GetSection("AllowedOrigins").Get<string[]>() ?? ["http://localhost:7360"]).AllowAnyHeader().AllowAnyMethod()));
builder.Services.AddRateLimiter(o =>
{
    o.RejectionStatusCode = 429;
    o.AddPolicy("auth", http => RateLimitPartition.GetFixedWindowLimiter(http.Connection.RemoteIpAddress?.ToString() ?? "local", _ => new FixedWindowRateLimiterOptions { PermitLimit = 40, Window = TimeSpan.FromMinutes(1), QueueLimit = 0 }));
});
builder.Services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme).AddJwtBearer(o =>
{
    o.TokenValidationParameters = new()
    {
        ValidateIssuer = true,
        ValidateAudience = true,
        ValidateLifetime = true,
        ValidateIssuerSigningKey = true,
        ValidIssuer = builder.Configuration["Jwt:Issuer"],
        ValidAudience = builder.Configuration["Jwt:Audience"],
        IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(secret)),
        ClockSkew = TimeSpan.FromSeconds(15)
    };
    o.Events = new JwtBearerEvents
    {
        OnTokenValidated = async c =>
        {
            if (!Guid.TryParse(c.Principal?.FindFirstValue(ClaimTypes.NameIdentifier), out var memberId) || !Guid.TryParse(c.Principal?.FindFirstValue("sid"), out var sessionId))
            {
                c.Fail("Invalid session");
                return;
            }
            var db = c.HttpContext.RequestServices.GetRequiredService<SportsBookingContext>();
            var current = await (from session in db.AuthSessions.AsNoTracking() join member in db.Members.AsNoTracking() on session.MemberId equals member.Id join role in db.Roles.AsNoTracking() on member.RoleId equals role.Id where session.Id == sessionId && member.Id == memberId select new { member.IsLocked, member.SecurityVersion, Role = role.Name, session.ExpiresAt, session.RevokedAt }).SingleOrDefaultAsync();
            if (current == null || current.IsLocked || current.RevokedAt != null || current.ExpiresAt <= DateTime.UtcNow || current.SecurityVersion.ToString() != c.Principal!.FindFirstValue("securityVersion") || current.Role != c.Principal.FindFirstValue(ClaimTypes.Role))
            {
                c.Fail("Session revoked");
            }
        }
    };
});
builder.Services.AddAuthorization();
var app = builder.Build();
app.Use(async (ctx, next) =>
{
    try
    {
        await next();
    }
    catch (BusinessException e) { await Results.Problem(statusCode: e.Status, title: e.Message, extensions: new Dictionary<string, object?> { { "code", e.Code } }).ExecuteAsync(ctx); }
    catch (DbUpdateConcurrencyException) { await Results.Problem(statusCode: 409, title: "Thông tin đã thay đổi. Vui lòng tải lại.", extensions: new Dictionary<string, object?> { { "code", "DATA_CHANGED" } }).ExecuteAsync(ctx); }
    catch (Exception e) when (IsConflict(e)) { await Results.Problem(statusCode: 409, title: "Dữ liệu bị trùng hoặc vừa thay đổi. Vui lòng tải lại.", extensions: new Dictionary<string, object?> { { "code", "DATA_CONFLICT" } }).ExecuteAsync(ctx); }
    catch (Exception e) { app.Logger.LogError(e, "Unhandled request failure"); await Results.Problem(statusCode: 500, title: "Máy chủ gặp lỗi. Vui lòng thử lại.").ExecuteAsync(ctx); }
});
app.UseCors();
app.UseStaticFiles();
app.UseAuthentication();
app.UseAuthorization();
app.UseRateLimiter();
app.MapControllers();
app.MapGet("/health", () => new { status = "ok", stage = 3 });
if (args.Contains("--init-db"))
{
    using var scope = app.Services.CreateScope();
    await DatabaseSeeder.Run(scope.ServiceProvider.GetRequiredService<SportsBookingContext>(), builder.Configuration);
    if (args.Contains("--init-only"))
    {
        return;
    }
}
app.Run();
static bool IsConflict(Exception e) { for (Exception? error = e; error != null; error = error.InnerException) { if (error is Microsoft.Data.SqlClient.SqlException sql && sql.Number is 2601 or 2627 or 547 or 1205) { return true; } } return false; }
