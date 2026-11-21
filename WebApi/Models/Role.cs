using System.ComponentModel.DataAnnotations;

namespace WebApi.Models;

public class Role
{
    public short Id { get; set; }
    [MaxLength(20)] public string Name { get; set; } = "";
}
