using System.ComponentModel.DataAnnotations;

namespace WebApi.Models;

public class CourtProfile
{
    public int ProductId
    { get; set; }
    public short Capacity
    { get; set; }
    [MaxLength(100)]
    public string? Surface
    { get; set; }
    public bool Indoor
    { get; set; }
    public short SlotMinutes { get; set; } = 30;
}
