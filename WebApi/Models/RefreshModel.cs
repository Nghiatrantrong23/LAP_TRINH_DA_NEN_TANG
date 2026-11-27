using System.ComponentModel.DataAnnotations;

namespace WebApi.Models;

public class RefreshModel
{
    [Required, MaxLength(200)]
    public string RefreshToken { get; set; } = string.Empty;
}
