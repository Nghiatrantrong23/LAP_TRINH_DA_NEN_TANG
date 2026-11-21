using System.ComponentModel.DataAnnotations;

namespace WebApi.Models;

public class CourtSchedule
{
    public int Id { get; set; }
    public int CourtId { get; set; }
    public byte DayOfWeek { get; set; }
    public TimeOnly OpenTime { get; set; }
    public TimeOnly CloseTime { get; set; }
    public bool IsClosed { get; set; }
}
