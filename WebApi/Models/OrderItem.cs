using System.ComponentModel.DataAnnotations;

namespace WebApi.Models;

public class OrderItem
{
    public long Id { get; set; }
    public Guid OrderId { get; set; }
    public int ProductId { get; set; }
    [MaxLength(150)] public string ProductName { get; set; } = "";
    [MaxLength(10)] public string ProductType { get; set; } = "";
    [MaxLength(30)] public string Unit { get; set; } = "";
    public int Quantity { get; set; }
    public decimal? UnitPrice { get; set; }
    public decimal LineTotal { get; set; }
}
