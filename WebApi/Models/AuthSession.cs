using System.ComponentModel.DataAnnotations;

namespace WebApi.Models;

public class AuthSession
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid MemberId
    {
        get; set;
    }
    [MaxLength(32)] public byte[] RefreshTokenHash { get; set; } = [];
    public DateTime ExpiresAt
    {
        get; set;
    }
    public DateTime? RevokedAt
    {
        get; set;
    }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public byte[] RowVersion { get; set; } = [];
}
