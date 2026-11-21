using System.ComponentModel.DataAnnotations;

namespace WebApi.Models;

public class UpdateRoleModel
{
    public short RoleId
    {
        get; set;
    }
    [Required]
    public string RowVersion { get; set; } = string.Empty;
}
