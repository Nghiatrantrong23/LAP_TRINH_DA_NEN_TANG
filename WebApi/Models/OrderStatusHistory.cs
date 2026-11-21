using System.ComponentModel.DataAnnotations;

namespace WebApi.Models;

public class OrderStatusHistory
{
    public long Id
    {
        get; set;
    }
    public Guid OrderId
    {
        get; set;
    }
    [MaxLength(30)]
    public string? FromStatus
    {
        get; set;
    }
    [MaxLength(30)] public string ToStatus { get; set; } = "";
    public Guid? ChangedByMemberId
    {
        get; set;
    }
    [MaxLength(500)]
    public string? Reason
    {
        get; set;
    }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
}
