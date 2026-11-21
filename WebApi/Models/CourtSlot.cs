using System.ComponentModel.DataAnnotations;

namespace WebApi.Models;

public class CourtSlot
{
    public long Id
    {
        get; set;
    }
    public int CourtId
    {
        get; set;
    }
    public DateOnly PlayDate
    {
        get; set;
    }
    public TimeOnly StartTime
    {
        get; set;
    }
    public TimeOnly EndTime
    {
        get; set;
    }
    public bool IsBlocked
    {
        get; set;
    }
    [MaxLength(300)]
    public string? BlockReason
    {
        get; set;
    }
    public byte[] RowVersion { get; set; } = [];
}
