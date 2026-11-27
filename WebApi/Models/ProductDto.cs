namespace WebApi.Models;
public class ProductDto
{
    public int Id { get; set; }
    public int CategoryId { get; set; }
    public string CategoryName { get; set; } = "";
    public int VenueId { get; set; }
    public string VenueName { get; set; } = "";
    public string Type { get; set; } = "";
    public string Name { get; set; } = "";
    public string? Description { get; set; }
    public string? ImagePath { get; set; }
    public decimal BasePrice { get; set; }
    public string Unit { get; set; } = "";
    public bool IsActive { get; set; }
    public string RowVersion { get; set; } = "";
    public short? Capacity { get; set; }
    public bool? Indoor { get; set; }
    public string? Surface { get; set; }
    public TimeOnly? OpenTime { get; set; }
    public TimeOnly? CloseTime { get; set; }
    public TimeOnly? PeakStartTime { get; set; }
    public TimeOnly? PeakEndTime { get; set; }
    public decimal? PeakPrice { get; set; }
}
