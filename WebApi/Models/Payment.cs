using System.ComponentModel.DataAnnotations;

namespace WebApi.Models;

public class Payment
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid OrderId { get; set; }
    [MaxLength(20)] public string Kind { get; set; } = "Deposit";
    [MaxLength(20)] public string Method { get; set; } = "BankTransfer";
    public decimal Amount { get; set; }
    [MaxLength(20)] public string Status { get; set; } = "Pending";
    [MaxLength(100)] public string TransferContent { get; set; } = "";
    [MaxLength(100)] public string? ExternalReference { get; set; }
    public Guid? VerifiedByMemberId { get; set; }
    public DateTime? ConfirmedAt { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public byte[] RowVersion { get; set; } = [];
}
