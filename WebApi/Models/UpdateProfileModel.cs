using System.ComponentModel.DataAnnotations;

namespace WebApi.Models;

public class UpdateProfileModel
{
    [Required, MaxLength(50)]
    public string GivenName { get; set; } = string.Empty;
    [MaxLength(50)]
    public string Surname { get; set; } = string.Empty;
    [MaxLength(20)]
    public string? Phone
    {
        get; set;
    }
    [Required]
    public string RowVersion { get; set; } = string.Empty;
}
