namespace WebApi.Models;

public class RegisterModel
{
    public string Email { get; set; } = null!;
    public string Password { get; set; } = null!;
    public string GivenName { get; set; } = null!; // Tên
    public string? Surname { get; set; }          // Họ
    public string? Phone { get; set; }            // Số điện thoại
}

public class LoginModel
{
    public string Email { get; set; } = null!;
    public string Password { get; set; } = null!;
}

public class LoginResponse
{
    public bool Success { get; set; }
    public string? Token { get; set; }
    public string? RefreshToken { get; set; }
    public string Message { get; set; } = null!;
    public string? Role { get; set; }
    public string? Email { get; set; }
    public string? FullName { get; set; }
    public string? MemberId { get; set; }
}

public class VerifyEmailModel
{
    public string Email { get; set; } = null!;
    public string Code { get; set; } = null!;
}

public class ForgotPasswordModel
{
    public string Email { get; set; } = null!;
}

public class ResetPasswordModel
{
    public string Email { get; set; } = null!;
    public string Code { get; set; } = null!;
    public string NewPassword { get; set; } = null!;
}

public class ChangePasswordModel
{
    public string OldPassword { get; set; } = null!;
    public string NewPassword { get; set; } = null!;
}

public class ExternalLoginModel
{
    public string Provider { get; set; } = null!; // 'Google', 'Facebook', 'Zalo'
    public string ProviderKey { get; set; } = null!;
    public string Email { get; set; } = null!;
    public string FullName { get; set; } = null!;
}

public class SocialTokenLoginModel
{
    public string Token { get; set; } = null!;
}

public class UpdateProfileModel
{
    public string GivenName { get; set; } = null!;
    public string? Surname { get; set; }
    public string? Phone { get; set; }
}

public class ChangeRoleModel
{
    public Guid MemberId { get; set; }
    public short RoleId { get; set; }
}

// DTOs Quản lý đơn hàng (Admin)
public class OrderDto
{
    public Guid MaDonHang { get; set; }
    public string SoDonHang { get; set; } = null!;
    public Guid MaThanhVien { get; set; }
    public int MaCoSo { get; set; }
    public string NgayDatChoi { get; set; } = null!;
    public string TenKhachHang { get; set; } = null!;
    public string SoDienThoaiKhach { get; set; } = null!;
    public string TrangThai { get; set; } = null!; // ChoCoc, DaXacNhan, DangChoi, HoanThanh, DaHuy
    public string TrangThaiText { get; set; } = null!;
    public decimal TongTien { get; set; }
    public decimal TienCoc { get; set; }
    public string? GhiChu { get; set; }
    public DateTime NgayTao { get; set; }
    public DateTime? NgayCapNhat { get; set; }
    public int SoLuongMatHang { get; set; }
    public List<OrderItemDto> ChiTiet { get; set; } = new();
}

public class OrderItemDto
{
    public long MaChiTietDon { get; set; }
    public int MaSanPham { get; set; }
    public string TenSanPham { get; set; } = null!;
    public string LoaiSanPham { get; set; } = null!;
    public string DonViTinh { get; set; } = null!;
    public int SoLuong { get; set; }
    public decimal? DonGia { get; set; }
    public decimal ThanhTien { get; set; }
}

public class UpdateOrderStatusModel
{
    public string TrangThai { get; set; } = null!;
    public string? LyDo { get; set; }
}

public class OrderStatusDefinitionDto
{
    public string Code { get; set; } = null!;
    public string Name { get; set; } = null!;
    public string Color { get; set; } = null!;
}
