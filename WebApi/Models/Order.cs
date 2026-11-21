using System.ComponentModel.DataAnnotations;

namespace WebApi.Models;

public class Order
{
    public Guid Id { get; set; } = Guid.NewGuid();
    [MaxLength(40)] public string OrderCode { get; set; } = "";
    public Guid MemberId
    {
        get; set;
    }
    public int VenueId
    {
        get; set;
    }
    public DateOnly BookingDate
    {
        get; set;
    }
    [MaxLength(120)] public string CustomerName { get; set; } = "";
    [MaxLength(20)] public string CustomerPhone { get; set; } = "";
    [MaxLength(30)] public string Status { get; set; } = "PendingDeposit";
    public decimal TotalAmount
    {
        get; set;
    }
    public decimal DepositAmount
    {
        get; set;
    }
    public DateTime? HoldExpiresAt
    {
        get; set;
    }
    [MaxLength(1000)]
    public string? Note
    {
        get; set;
    }
    [MaxLength(64)] public string IdempotencyKey { get; set; } = "";
    [MaxLength(32)] public byte[] RequestHash { get; set; } = [];
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime? UpdatedAt
    {
        get; set;
    }
    public byte[] RowVersion { get; set; } = [];
}
