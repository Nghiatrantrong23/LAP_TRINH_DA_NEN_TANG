using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Security.Cryptography;
using System.Text;
using Microsoft.IdentityModel.Tokens;
using WebApi.Models;
namespace WebApi.Services;
public static class Helper
{
    public static string NormalizeEmail(string email) => email.Trim().ToUpperInvariant();
    public static string NewRefreshToken() => Convert.ToBase64String(RandomNumberGenerator.GetBytes(64));
    public static byte[] HashToken(string token) => SHA256.HashData(Encoding.UTF8.GetBytes(token));
    public static void ValidatePassword(string password)
    {
        if (password.Length < 8 || Encoding.UTF8.GetByteCount(password) > 72)
        {
            throw new BusinessException(400, "INVALID_PASSWORD", "Mật khẩu cần ít nhất 8 ký tự và tối đa 72 byte UTF-8.");
        }
    }
    public static MemberDto ToDto(Member member)
    {
        return new MemberDto
        {
            Id = member.Id,
            Email = member.Email,
            GivenName = member.GivenName,
            Surname = member.Surname,
            Phone = member.Phone,
            RoleId = member.RoleId,
            Role = member.Role.Name,
            IsLocked = member.IsLocked,
            EmailConfirmed = member.EmailConfirmed,
            RowVersion = Convert.ToBase64String(member.RowVersion)
        };
    }
    public static void RequireVersion(Member member, string version)
    {
        if (version != Convert.ToBase64String(member.RowVersion))
        {
            throw new BusinessException(409, "MEMBER_CHANGED", "Thông tin vừa thay đổi. Vui lòng tải lại.");
        }
    }
    public static LoginResponse Tokens(Member member, AuthSession session, string refresh, IConfiguration config)
    {
        var expires = DateTime.UtcNow.AddMinutes(config.GetValue<int>("Jwt:AccessMinutes", 15));
        var token = new JwtSecurityToken(config["Jwt:Issuer"], config["Jwt:Audience"], [
            new Claim(ClaimTypes.NameIdentifier,member.Id.ToString()),
            new Claim(ClaimTypes.Role,member.Role.Name),
            new Claim("sid",session.Id.ToString()),
            new Claim("securityVersion",member.SecurityVersion.ToString()),
            new Claim(JwtRegisteredClaimNames.Jti,Guid.NewGuid().ToString("N"))
        ], expires: expires, signingCredentials: new SigningCredentials(new SymmetricSecurityKey(Encoding.UTF8.GetBytes(config["Jwt:SecretKey"]!)), SecurityAlgorithms.HmacSha256));
        return new LoginResponse
        {
            Success = true,
            Message = "Đăng nhập thành công.",
            Token = new JwtSecurityTokenHandler().WriteToken(token),
            RefreshToken = refresh,
            ExpiresAt = expires,
            Member = ToDto(member)
        };
    }
}
