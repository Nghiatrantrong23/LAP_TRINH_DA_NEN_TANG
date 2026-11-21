using System.ComponentModel.DataAnnotations;

namespace WebApi.Models;

public class Category
{
    public int Id
    {
        get; set;
    }
    [MaxLength(100)] public string Name { get; set; } = "";
    [MaxLength(1000)]
    public string? Description
    {
        get; set;
    }
    [MaxLength(500)]
    public string? ImagePath
    {
        get; set;
    }
    public int DisplayOrder
    {
        get; set;
    }
    public bool IsActive { get; set; } = true;
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public byte[] RowVersion { get; set; } = [];
}
