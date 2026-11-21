using System.ComponentModel.DataAnnotations;

namespace WebApi.Models;

public class CourtPriceRule
{
    public int Id { get; set; }
    public int CourtId { get; set; }
    public byte DayOfWeek { get; set; }
    public TimeOnly StartTime { get; set; }
    public TimeOnly EndTime { get; set; }
    public decimal PricePerHour { get; set; }
    public DateOnly EffectiveFrom { get; set; }
    public DateOnly? EffectiveTo { get; set; }
    public bool IsActive { get; set; } = true;
    public byte[] RowVersion { get; set; } = [];
}
