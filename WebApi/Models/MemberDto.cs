using System.ComponentModel.DataAnnotations;

namespace WebApi.Models;

public class MemberDto
{
    public Guid Id
    {
        get; set;
    }
    public string Email { get; set; } = string.Empty;
    public string GivenName { get; set; } = string.Empty;
    public string Surname { get; set; } = string.Empty;
    public string? Phone
    {
        get; set;
    }
    public short RoleId
    {
        get; set;
    }
    public string Role { get; set; } = string.Empty;
    public bool IsLocked
    {
        get; set;
    }
    public bool EmailConfirmed
    {
        get; set;
    }
    public string RowVersion { get; set; } = string.Empty;
}
