using System.ComponentModel.DataAnnotations;

namespace WebApi.Models;

public class Member
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public short RoleId { get; set; } = 1;
    public Role Role { get; set; } = null!;
    [MaxLength(50)] public string GivenName { get; set; } = "";
    [MaxLength(50)] public string Surname { get; set; } = "";
    [MaxLength(254)] public string Email { get; set; } = "";
    [MaxLength(254)] public string NormalizedEmail { get; set; } = "";
    [MaxLength(20)]
    public string? Phone
    { get; set; }
    [MaxLength(255)] public string PasswordHash { get; set; } = "";
    public bool IsLocked
    { get; set; }
    public bool EmailConfirmed
    { get; set; }
    public int SecurityVersion
    { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime? UpdatedAt
    { get; set; }
    public byte[] RowVersion { get; set; } = [];
}
