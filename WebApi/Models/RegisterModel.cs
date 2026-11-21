using System.ComponentModel.DataAnnotations;

namespace WebApi.Models;

public class RegisterModel
{
    [Required, EmailAddress, MaxLength(254)]
    public string Email { get; set; } = string.Empty;
    [Required, MinLength(8), MaxLength(72)]
    public string Password { get; set; } = string.Empty;
    [Required, MaxLength(50)]
    public string GivenName { get; set; } = string.Empty;
    [MaxLength(50)]
    public string Surname { get; set; } = string.Empty;
    [MaxLength(20)]
    public string? Phone
    {
        get; set;
    }
}
