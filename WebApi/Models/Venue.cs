using System.ComponentModel.DataAnnotations;

namespace WebApi.Models;

public class Venue
{
    public int Id
    {
        get; set;
    }
    [MaxLength(150)] public string Name { get; set; } = "";
    [MaxLength(300)] public string Address { get; set; } = "";
    [MaxLength(20)] public string Phone { get; set; } = "";
    public bool IsActive { get; set; } = true;
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
}
