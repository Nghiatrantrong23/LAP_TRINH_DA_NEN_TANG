namespace WebApi.Models;

public class OrderDto
{
    public Guid MaDonHang { get; set; }
    public string SoDonHang { get; set; } = "";
    public Guid MaThanhVien { get; set; }
    public int MaCoSo { get; set; }
    public string NgayDatChoi { get; set; } = "";
    public string TenKhachHang { get; set; } = "";
    public string SoDienThoaiKhach { get; set; } = "";
    public string TrangThai { get; set; } = "";
    public string TrangThaiText { get; set; } = "";
    public decimal TongTien { get; set; }
    public decimal TienCoc { get; set; }
    public string? GhiChu { get; set; }
    public DateTime NgayTao { get; set; }
    public DateTime? NgayCapNhat { get; set; }
    public int SoLuongMatHang { get; set; }
    public List<OrderItemDto> ChiTiet { get; set; } = new();

    public Guid Id => MaDonHang;
    public string OrderCode => SoDonHang;
    public string Status => TrangThai;
    public decimal TotalAmount => TongTien;
    public decimal DepositAmount => TienCoc;
    public List<OrderItemDto> Items => ChiTiet;
}

public class OrderItemDto
{
    public long MaChiTietDon { get; set; }
    public int MaSanPham { get; set; }
    public string TenSanPham { get; set; } = "";
    public string LoaiSanPham { get; set; } = "San";
    public string DonViTinh { get; set; } = "";
    public int SoLuong { get; set; } = 1;
    public decimal? DonGia { get; set; }
    public decimal ThanhTien { get; set; }

    public long Id => MaChiTietDon;
    public int ProductId => MaSanPham;
    public string ProductName => TenSanPham;
    public string ProductType => LoaiSanPham;
    public decimal LineTotal => ThanhTien;
}

public class UpdateOrderStatusModel
{
    public string TrangThai { get; set; } = "";
    public string? LyDo { get; set; }
}

public class OrderStatusDefinitionDto
{
    public string Code { get; set; } = "";
    public string Name { get; set; } = "";
    public string Color { get; set; } = "";
}
