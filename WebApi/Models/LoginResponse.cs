using System.ComponentModel.DataAnnotations;

namespace WebApi.Models;

public class LoginResponse
{
    public bool Success
    {
        get; set;
    }
    public string Message { get; set; } = string.Empty;
    public string Token { get; set; } = string.Empty;
    public string RefreshToken { get; set; } = string.Empty;
    public DateTime ExpiresAt
    {
        get; set;
    }
    public MemberDto Member { get; set; } = null!;
}
