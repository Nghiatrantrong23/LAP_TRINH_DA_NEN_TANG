using System.ComponentModel.DataAnnotations;

namespace WebApi.Models;

public class CheckInToken
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid OrderId
    { get; set; }
    [MaxLength(32)] public byte[] TokenHash { get; set; } = [];
    public DateTime ExpiresAt
    { get; set; }
    public DateTime? UsedAt
    { get; set; }
    public DateTime? RevokedAt
    { get; set; }
    public Guid? UsedByMemberId
    { get; set; }
}
