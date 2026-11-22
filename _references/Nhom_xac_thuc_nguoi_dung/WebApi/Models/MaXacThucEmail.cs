using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace WebApi.Models;

[Table("MaXacThucEmail")]
public class MaXacThucEmail
{
    [Key]
    public Guid MaYeuCau { get; set; } = Guid.NewGuid();

    public Guid MaThanhVien { get; set; }

    [ForeignKey("MaThanhVien")]
    public ThanhVien? ThanhVien { get; set; }

    [Required, MaxLength(30)]
    public string MucDich { get; set; } = null!; // XacThucEmail | QuenMatKhau

    [Required, MaxLength(32)]
    public byte[] MaCodeHash { get; set; } = null!;

    public DateTime HetHanLuc { get; set; }

    public DateTime? DaDungLuc { get; set; }

    public short SoLanSai { get; set; } = 0;

    public DateTime NgayTao { get; set; } = DateTime.UtcNow;
}

