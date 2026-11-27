using System.ComponentModel.DataAnnotations;

namespace WebApi.Models;

public class EmailOtpModel
{
    [Required, RegularExpression("^[0-9]{6}$")]
    public string Otp { get; set; } = string.Empty;
}

public class ForgotPasswordModel
{
    [Required, EmailAddress, MaxLength(254)]
    public string Email { get; set; } = string.Empty;
}

public class ResetPasswordModel : EmailOtpModel
{
    [Required, EmailAddress, MaxLength(254)]
    public string Email { get; set; } = string.Empty;
    [Required, MinLength(8), MaxLength(72)]
    public string NewPassword { get; set; } = string.Empty;
}

public class ExternalLoginModel : ForgotPasswordModel
{
    [Required, MaxLength(20)]
    public string Provider { get; set; } = string.Empty;
    [Required, MaxLength(50)]
    public string Name { get; set; } = string.Empty;
    [Required, MaxLength(50)]
    public string ProviderKey { get; set; } = string.Empty;
}
