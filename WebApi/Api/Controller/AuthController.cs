using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.RateLimiting;
using WebApi.Models;
using WebApi.Services;
namespace WebApi.Api.Controller;
[ApiController, Route("api/auth")]
public class AuthController : BaseController
{
    [HttpPost("register"), HttpPost("/api/register"), EnableRateLimiting("auth")]
    public async Task<IActionResult> Register(RegisterModel model)
    {
        return StatusCode(201, await Provider.Auth.Register(model));
    }
    [HttpPost("login"), HttpPost("/api/login"), EnableRateLimiting("auth")]
    public Task<LoginResponse> Login(LoginModel model)
    {
        return Provider.Auth.Login(model);
    }
    [HttpPost("refresh"), EnableRateLimiting("auth")]
    public Task<LoginResponse> Refresh(RefreshModel model)
    {
        return Provider.Auth.Refresh(model.RefreshToken);
    }
    [HttpGet, Authorize]
    [HttpGet("me")]
    public Task<MemberDto> GetMember()
    {
        return Provider.Member.GetMember(MemberId);
    }
    [HttpPost("logout"), Authorize]
    public async Task<IActionResult> Logout()
    {
        await Provider.Auth.Logout(MemberId, SessionId);
        return NoContent();
    }
    [HttpPost("send-verification-email"), Authorize, EnableRateLimiting("auth")]
    public async Task<IActionResult> SendVerificationEmail([FromServices] IEmailService emailService)
    {
        await Provider.Auth.SendVerificationEmail(MemberId, emailService);
        return NoContent();
    }

    [HttpPost("verify-email"), Authorize, EnableRateLimiting("auth")]
    public async Task<IActionResult> VerifyEmail(EmailOtpModel model)
    {
        await Provider.Auth.VerifyEmail(MemberId, model.Otp);
        return NoContent();
    }

    [HttpPost("forgot-password"), EnableRateLimiting("auth")]
    public async Task<IActionResult> ForgotPassword(ForgotPasswordModel model, [FromServices] IEmailService emailService)
    {
        await Provider.Auth.ForgotPassword(model.Email, emailService);
        return NoContent();
    }

    [HttpPost("reset-password"), EnableRateLimiting("auth")]
    public async Task<IActionResult> ResetPassword(ResetPasswordModel model)
    {
        await Provider.Auth.ResetPassword(model);
        return NoContent();
    }

    [HttpPost("external-login"), EnableRateLimiting("auth")]
    public async Task<ActionResult<LoginResponse>> ExternalLogin(ExternalLoginModel model,
        [FromServices] IWebHostEnvironment environment, [FromServices] IConfiguration configuration)
    {
        if (!environment.IsDevelopment() || !configuration.GetValue<bool>("AuthDemo:ExternalLogin")) return NotFound();
        return await Provider.Auth.ExternalLogin(model);
    }

    [HttpPut("password"), Authorize]
    public async Task<IActionResult> Password(ChangePasswordModel model)
    {
        await Provider.Auth.ChangePassword(MemberId, model);
        return NoContent();
    }
}
