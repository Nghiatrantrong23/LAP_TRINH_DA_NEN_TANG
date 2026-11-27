using System.ComponentModel.DataAnnotations;

namespace WebApi.Models;

public class MatchRequest
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid RoomId
    { get; set; }
    public Guid MemberId
    { get; set; }
    [MaxLength(20)] public string Status { get; set; } = "Pending";
    [MaxLength(500)]
    public string? Message
    { get; set; }
    public Guid? ReviewedByMemberId
    { get; set; }
    public DateTime? ReviewedAt
    { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public byte[] RowVersion { get; set; } = [];
}
