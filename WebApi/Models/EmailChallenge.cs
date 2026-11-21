using System.ComponentModel.DataAnnotations;

namespace WebApi.Models;

public class EmailChallenge
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid MemberId
    { get; set; }
    [MaxLength(30)] public string Purpose { get; set; } = "";
    [MaxLength(32)] public byte[] CodeHash { get; set; } = [];
    public DateTime ExpiresAt
    { get; set; }
    public DateTime? ConsumedAt
    { get; set; }
    public short FailedAttempts
    { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
}
