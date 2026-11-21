using System.ComponentModel.DataAnnotations;

namespace WebApi.Models;

public class LockMemberModel
{
    public bool IsLocked
    { get; set; }
    [Required]
    public string RowVersion { get; set; } = string.Empty;
}
