using System.ComponentModel.DataAnnotations;
namespace WebApi.Models;
public class ProductModel
{
    public int CategoryId { get; set; }
    public int VenueId { get; set; }
    [Required, MaxLength(10)] public string Type { get; set; } = "Court";
    [Required, MaxLength(150)] public string Name { get; set; } = "";
    [MaxLength(5000)] public string? Description { get; set; }
    [Range(0, 100000000)] public decimal BasePrice { get; set; }
    [Required, MaxLength(30)] public string Unit { get; set; } = "giờ";
    public bool IsActive { get; set; } = true;
    [MaxLength(100)] public string? RowVersion { get; set; }
    public IFormFile? Image { get; set; }
    public short? Capacity { get; set; }
    public bool Indoor { get; set; }
    [MaxLength(100)] public string? Surface { get; set; }
    public TimeOnly? OpenTime { get; set; }
    public TimeOnly? CloseTime { get; set; }
    public TimeOnly? PeakStartTime { get; set; }
    public TimeOnly? PeakEndTime { get; set; }
    [Range(0, 100000000)] public decimal? PeakPrice { get; set; }
}
