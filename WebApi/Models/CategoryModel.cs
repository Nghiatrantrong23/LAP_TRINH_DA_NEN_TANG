using System.ComponentModel.DataAnnotations;
namespace WebApi.Models;
public class CategoryModel
{
    [Required, MaxLength(100)] public string Name { get; set; } = "";
    [MaxLength(1000)] public string? Description { get; set; }
    [Range(0, 10000)] public int DisplayOrder { get; set; }
    public bool IsActive { get; set; } = true;
    [MaxLength(100)] public string? RowVersion { get; set; }
    public IFormFile? Image { get; set; }
}
