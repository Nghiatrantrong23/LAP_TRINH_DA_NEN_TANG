using System.ComponentModel.DataAnnotations;

namespace WebApi.Models;

public class OrderItemSlot
{
    public long OrderItemId
    { get; set; }
    public long CourtSlotId
    { get; set; }
    public decimal UnitPrice
    { get; set; }
}
