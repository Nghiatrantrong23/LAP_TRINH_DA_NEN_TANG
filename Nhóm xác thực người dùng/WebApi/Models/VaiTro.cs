using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace WebApi.Models;

[Table("VaiTro")]
public class VaiTro
{
    [Key, DatabaseGenerated(DatabaseGeneratedOption.None)]
    public short MaVaiTro { get; set; }

    [Required, MaxLength(20)]
    public string TenVaiTro { get; set; } = null!;
}

