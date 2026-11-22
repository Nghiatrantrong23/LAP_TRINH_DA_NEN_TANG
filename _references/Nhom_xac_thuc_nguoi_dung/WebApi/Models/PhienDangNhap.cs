using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace WebApi.Models;

[Table("PhienDangNhap")]
public class PhienDangNhap
{
    [Key]
    public Guid MaPhien { get; set; } = Guid.NewGuid();

    public Guid MaThanhVien { get; set; }

    [ForeignKey("MaThanhVien")]
    public ThanhVien? ThanhVien { get; set; }

    [Required, MaxLength(32)]
    public byte[] RefreshTokenHash { get; set; } = null!;

    public DateTime HetHanLuc { get; set; }

    public DateTime? ThuHoiLuc { get; set; }

    public DateTime NgayTao { get; set; } = DateTime.UtcNow;
}

