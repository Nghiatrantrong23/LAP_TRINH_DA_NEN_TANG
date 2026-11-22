using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using WebApi.Models;

namespace WebApi.Api.Controllers;

// Quản lý Member (0.25đ) & Phân quyền Admin (0.5đ)
[Authorize(Roles = "Admin"), ApiController, Route("api/[controller]")]
public class MemberController : BaseController
{
    // Lấy toàn bộ danh sách thành viên kèm vai trò
    [HttpGet]
    public IEnumerable<object> GetMembers()
    {
        return Provider.ThanhVien.GetMembers().Select(p => new
        {
            MemberId = p.MaThanhVien.ToString(),
            p.Email,
            GivenName = p.Ten,
            Surname = p.Ho,
            FullName = string.IsNullOrEmpty(p.Ho) ? p.Ten : $"{p.Ho} {p.Ten}",
            Phone = p.SoDienThoai,
            RoleId = p.MaVaiTro,
            RoleName = p.VaiTro?.TenVaiTro,
            IsEmailConfirmed = p.DaXacThucEmail,
            IsActive = !p.BiKhoa,
            p.NgayTao
        });
    }

    // Xem chi tiết một thành viên
    [HttpGet("{id}")]
    public IActionResult GetMember(Guid id)
    {
        ThanhVien? p = Provider.ThanhVien.GetMember(id);
        if (p is null) return NotFound(new { message = "Không tìm thấy thành viên" });

        return Ok(new
        {
            MemberId = p.MaThanhVien.ToString(),
            p.Email,
            GivenName = p.Ten,
            Surname = p.Ho,
            Phone = p.SoDienThoai,
            RoleId = p.MaVaiTro,
            RoleName = p.VaiTro?.TenVaiTro,
            IsEmailConfirmed = p.DaXacThucEmail,
            IsActive = !p.BiKhoa,
            p.NgayTao
        });
    }

    // Khóa hoặc mở khóa tài khoản thành viên
    [HttpPut("toggle-status/{id}")]
    public IActionResult ToggleStatus(Guid id)
    {
        int ret = Provider.ThanhVien.ToggleStatus(id);
        if (ret == -1) return NotFound(new { code = -1, message = "Không tìm thấy thành viên" });
        if (ret == -2) return BadRequest(new { code = -2, message = "Không thể khóa tài khoản Admin mặc định" });

        return Ok(new { code = ret, message = "Thay đổi trạng thái tài khoản thành công" });
    }

    // Thay đổi quyền (Role) cho thành viên
    [HttpPut("change-role")]
    public IActionResult ChangeRole(ChangeRoleModel obj)
    {
        int ret = Provider.ThanhVien.ChangeRole(obj.MemberId, obj.RoleId);
        if (ret == -1) return NotFound(new { code = -1, message = "Không tìm thấy thành viên" });
        if (ret == -2) return BadRequest(new { code = -2, message = "Role chỉ định không tồn tại" });

        return Ok(new { code = ret, message = "Cập nhật vai trò thành công" });
    }
}
