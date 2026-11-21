using System.ComponentModel.DataAnnotations;

namespace WebApi.Models;

public class CartItem
{
    public long Id
    { get; set; }
    public Guid CartId
    { get; set; }
    public int ProductId
    { get; set; }
    public DateOnly? PlayDate
    { get; set; }
    public TimeOnly? StartTime
    { get; set; }
    public short? SlotCount
    { get; set; }
    public int Quantity { get; set; } = 1;
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
}
