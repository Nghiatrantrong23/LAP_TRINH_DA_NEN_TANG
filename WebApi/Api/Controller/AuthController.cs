using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.RateLimiting;
using WebApi.Models;
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
    [HttpPut("password"), Authorize]
    public async Task<IActionResult> Password(ChangePasswordModel model)
    {
        await Provider.Auth.ChangePassword(MemberId, model);
        return NoContent();
    }
}
