using System.ComponentModel.DataAnnotations;

namespace WebApi.Models;

public class MatchRoom
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public long OrderItemId
    { get; set; }
    public Guid OwnerMemberId
    { get; set; }
    [MaxLength(150)] public string Title { get; set; } = "";
    [MaxLength(30)] public string RequiredLevel { get; set; } = "Beginner";
    public short NeededPlayers
    { get; set; }
    public decimal CostPerPerson
    { get; set; }
    [MaxLength(1000)]
    public string? Description
    { get; set; }
    [MaxLength(20)] public string Status { get; set; } = "Open";
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public byte[] RowVersion { get; set; } = [];
}
