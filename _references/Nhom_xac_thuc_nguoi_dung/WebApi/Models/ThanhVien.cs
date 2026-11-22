using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace WebApi.Models;

[Table("ThanhVien")]
public class ThanhVien
{
    [Key]
    public Guid MaThanhVien { get; set; } = Guid.NewGuid();

    public short MaVaiTro { get; set; } = 2; // 1: Admin, 2: Member

    [ForeignKey("MaVaiTro")]
    public VaiTro? VaiTro { get; set; }

    [Required, MaxLength(50)]
    public string Ten { get; set; } = null!;

    [Required, MaxLength(50)]
    public string Ho { get; set; } = null!;

    [Required, MaxLength(254)]
    public string Email { get; set; } = null!;

    [Required, MaxLength(254)]
    public string EmailChuanHoa { get; set; } = null!;

    [MaxLength(20)]
    public string? SoDienThoai { get; set; }

    [Required, MaxLength(255)]
    public string MatKhauHash { get; set; } = null!;

    public bool BiKhoa { get; set; } = false;

    public bool DaXacThucEmail { get; set; } = false;

    public int PhienBanBaoMat { get; set; } = 1;

    public DateTime NgayTao { get; set; } = DateTime.UtcNow;

    public DateTime? NgayCapNhat { get; set; }

    [Timestamp]
    public byte[]? RowVersion { get; set; }
}

