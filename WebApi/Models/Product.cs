using System.ComponentModel.DataAnnotations;

namespace WebApi.Models;

public class Product
{
    public int Id
    { get; set; }
    public int CategoryId
    { get; set; }
    public int VenueId
    { get; set; }
    [MaxLength(10)] public string Type { get; set; } = "Court";
    [MaxLength(150)] public string Name { get; set; } = "";
    public string? Description
    { get; set; }
    [MaxLength(500)]
    public string? ImagePath
    { get; set; }
    public decimal BasePrice
    { get; set; }
    [MaxLength(30)] public string Unit { get; set; } = "giờ";
    public bool IsActive { get; set; } = true;
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime? UpdatedAt
    { get; set; }
    public byte[] RowVersion { get; set; } = [];
}
