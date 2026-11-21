using System.ComponentModel.DataAnnotations;

namespace WebApi.Models;

public class ChangePasswordModel
{
    [Required]
    public string CurrentPassword { get; set; } = string.Empty;
    [Required, MinLength(8), MaxLength(72)]
    public string NewPassword { get; set; } = string.Empty;
}
