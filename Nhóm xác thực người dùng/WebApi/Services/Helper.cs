using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Security.Cryptography;
using System.Text;
using Microsoft.IdentityModel.Tokens;
using WebApi.Models;

namespace WebApi.Services;

public static class Helper
{
    // Sinh mã OTP ngẫu nhiên (mặc định 6 chữ số)
    public static string GenerateOtp(int len = 6)
    {
        Random rand = new Random();
        char[] digits = new char[len];
        for (int i = 0; i < len; i++)
        {
            digits[i] = (char)('0' + rand.Next(0, 10));
        }
        return new string(digits);
    }

    // Băm SHA256 cho mã OTP hoặc RefreshToken (đúng kiểu BINARY(32) trong SQL)
    public static byte[] ComputeHashSha256(string raw)
    {
        using (SHA256 sha256 = SHA256.Create())
        {
            return sha256.ComputeHash(Encoding.UTF8.GetBytes(raw));
        }
    }

    // Sinh chuỗi Refresh Token ngẫu nhiên
    public static string GenerateRefreshToken()
    {
        byte[] randomNumber = new byte[32];
        using (var rng = RandomNumberGenerator.Create())
        {
            rng.GetBytes(randomNumber);
            return Convert.ToBase64String(randomNumber);
        }
    }

    // Mã hóa mật khẩu BCrypt
    public static string HashPassword(string password)
    {
        return BCrypt.Net.BCrypt.HashPassword(password);
    }

    // Kiểm tra mật khẩu BCrypt
    public static bool VerifyPassword(string password, string hashedPassword)
    {
        return BCrypt.Net.BCrypt.Verify(password, hashedPassword);
    }

    // Sinh JWT Access Token kèm Claim Role, Email, Name, Id
    public static string GenerateToken(ThanhVien thanhVien, IConfiguration configuration)
    {
        string roleName = thanhVien.VaiTro?.TenVaiTro ?? (thanhVien.MaVaiTro == 1 ? "Admin" : "Member");
        string fullName = string.IsNullOrEmpty(thanhVien.Ho) ? thanhVien.Ten : $"{thanhVien.Ho} {thanhVien.Ten}";

        List<Claim> claims = new List<Claim>
        {
            new Claim(ClaimTypes.NameIdentifier, thanhVien.MaThanhVien.ToString()),
            new Claim(ClaimTypes.Email, thanhVien.Email),
            new Claim(ClaimTypes.Name, fullName),
            new Claim(ClaimTypes.Role, roleName),
            new Claim("MaVaiTro", thanhVien.MaVaiTro.ToString()),
            new Claim(ClaimTypes.GivenName, thanhVien.Ten),
            new Claim("PhienBanBaoMat", thanhVien.PhienBanBaoMat.ToString())
        };

        if (!string.IsNullOrEmpty(thanhVien.Ho))
        {
            claims.Add(new Claim(ClaimTypes.Surname, thanhVien.Ho));
        }

        SymmetricSecurityKey key = new SymmetricSecurityKey(
            Encoding.ASCII.GetBytes(configuration["Jwt:SecretKey"] ?? throw new KeyNotFoundException("Jwt:SecretKey")));

        JwtSecurityToken token = new JwtSecurityToken(
            issuer: configuration["Jwt:Issuer"],
            audience: configuration["Jwt:Audience"],
            claims: claims,
            expires: DateTime.UtcNow.AddDays(int.Parse(configuration["Jwt:Expires"] ?? "30")),
            signingCredentials: new SigningCredentials(key, SecurityAlgorithms.HmacSha256Signature)
        );

        return new JwtSecurityTokenHandler().WriteToken(token);
    }
}
