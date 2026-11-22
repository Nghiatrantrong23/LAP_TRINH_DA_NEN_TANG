namespace WebApi.Models;

public class RegisterModel
{
    public string Email { get; set; } = null!;
    public string Password { get; set; } = null!;
    public string GivenName { get; set; } = null!; // Tên
    public string? Surname { get; set; }          // Họ
    public string? Phone { get; set; }            // Số điện thoại
}

public class LoginModel
{
    public string Email { get; set; } = null!;
    public string Password { get; set; } = null!;
}

public class LoginResponse
{
    public bool Success { get; set; }
    public string? Token { get; set; }
    public string? RefreshToken { get; set; }
    public string Message { get; set; } = null!;
    public string? Role { get; set; }
    public string? Email { get; set; }
    public string? FullName { get; set; }
    public string? MemberId { get; set; }
}

public class VerifyEmailModel
{
    public string Email { get; set; } = null!;
    public string Code { get; set; } = null!;
}

public class ForgotPasswordModel
{
    public string Email { get; set; } = null!;
}

public class ResetPasswordModel
{
    public string Email { get; set; } = null!;
    public string Code { get; set; } = null!;
    public string NewPassword { get; set; } = null!;
}

public class ChangePasswordModel
{
    public string OldPassword { get; set; } = null!;
    public string NewPassword { get; set; } = null!;
}

public class ExternalLoginModel
{
    public string Provider { get; set; } = null!; // 'Google', 'Facebook', 'Zalo'
    public string ProviderKey { get; set; } = null!;
    public string Email { get; set; } = null!;
    public string FullName { get; set; } = null!;
}

public class SocialTokenLoginModel
{
    public string Token { get; set; } = null!;
}

public class UpdateProfileModel
{
    public string GivenName { get; set; } = null!;
    public string? Surname { get; set; }
    public string? Phone { get; set; }
}

public class ChangeRoleModel
{
    public Guid MemberId { get; set; }
    public short RoleId { get; set; }
}
