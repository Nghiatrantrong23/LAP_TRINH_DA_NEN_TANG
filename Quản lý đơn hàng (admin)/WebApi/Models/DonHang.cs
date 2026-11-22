using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using System.Text.Json.Serialization;

namespace WebApi.Models;

[Table("DonHang")]
public class DonHang
{
    [Key]
    public Guid MaDonHang { get; set; }

    [MaxLength(30)]
    public string SoDonHang { get; set; } = null!;

    public Guid MaThanhVien { get; set; }

    public int MaCoSo { get; set; }

    public DateOnly NgayDatChoi { get; set; }

    [MaxLength(120)]
    public string TenKhachHang { get; set; } = null!;

    [MaxLength(20)]
    public string SoDienThoaiKhach { get; set; } = null!;

    [MaxLength(30)]
    public string TrangThai { get; set; } = null!; // ChoCoc, DaXacNhan, DangChoi, HoanThanh, DaHuy

    [Column(TypeName = "decimal(18,2)")]
    public decimal TongTien { get; set; }

    [Column(TypeName = "decimal(18,2)")]
    public decimal TienCoc { get; set; }

    public DateTime? GiuChoDen { get; set; }

    [MaxLength(1000)]
    public string? GhiChu { get; set; }

    [MaxLength(64)]
    public string KhoaChongTrung { get; set; } = null!;

    public byte[] RequestHash { get; set; } = null!;

    public DateTime NgayTao { get; set; }

    public DateTime? NgayCapNhat { get; set; }

    [ForeignKey("MaThanhVien")]
    public virtual ThanhVien? ThanhVien { get; set; }

    public virtual List<ChiTietDonHang> ChiTietDonHangs { get; set; } = new();
}

[Table("ChiTietDonHang")]
public class ChiTietDonHang
{
    [Key]
    [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
    public long MaChiTietDon { get; set; }

    public Guid MaDonHang { get; set; }

    public int MaSanPham { get; set; }

    [MaxLength(150)]
    public string TenSanPham { get; set; } = null!;

    [MaxLength(10)]
    public string LoaiSanPham { get; set; } = null!; // San, DichVu

    [MaxLength(30)]
    public string DonViTinh { get; set; } = null!;

    public int SoLuong { get; set; }

    [Column(TypeName = "decimal(18,2)")]
    public decimal? DonGia { get; set; }

    [Column(TypeName = "decimal(18,2)")]
    public decimal ThanhTien { get; set; }

    [ForeignKey("MaDonHang")]
    [JsonIgnore]
    public virtual DonHang? DonHang { get; set; }
}

[Table("LichSuTrangThaiDon")]
public class LichSuTrangThaiDon
{
    [Key]
    [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
    public long MaLichSu { get; set; }

    public Guid MaDonHang { get; set; }

    [MaxLength(30)]
    public string? TrangThaiCu { get; set; }

    [MaxLength(30)]
    public string TrangThaiMoi { get; set; } = null!;

    public Guid? NguoiThayDoi { get; set; }

    [MaxLength(500)]
    public string? LyDo { get; set; }

    public DateTime NgayTao { get; set; }
}

