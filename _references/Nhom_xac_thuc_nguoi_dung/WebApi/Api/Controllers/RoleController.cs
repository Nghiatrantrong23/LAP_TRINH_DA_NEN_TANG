using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using WebApi.Models;

namespace WebApi.Api.Controllers;

// Quản lý Role người dùng (0.5đ)
[Authorize(Roles = "Admin"), ApiController, Route("api/[controller]")]
public class RoleController : BaseController
{
    // Lấy danh sách toàn bộ các Vai trò
    [HttpGet]
    public IEnumerable<object> GetRoles()
    {
        return Provider.VaiTro.GetRoles().Select(p => new
        {
            RoleId = p.MaVaiTro,
            RoleName = p.TenVaiTro,
            Description = p.TenVaiTro == "Admin" ? "Quản trị viên toàn quyền hệ thống" : "Khách hàng đặt sân và dịch vụ"
        });
    }

    // Xem chi tiết Role theo Id
    [HttpGet("{id}")]
    public IActionResult GetRole(short id)
    {
        VaiTro? item = Provider.VaiTro.GetRole(id);
        if (item is null) return NotFound(new { message = "Không tìm thấy Role" });
        return Ok(new
        {
            RoleId = item.MaVaiTro,
            RoleName = item.TenVaiTro
        });
    }

    // Thêm Role mới
    [HttpPost]
    public IActionResult Add(VaiTro obj)
    {
        if (!ModelState.IsValid) return BadRequest(ModelState);

        int ret = Provider.VaiTro.Add(obj);
        if (ret == -1) return BadRequest(new { code = -1, message = "Tên hoặc mã vai trò đã tồn tại" });

        return Ok(new { code = ret, message = "Thêm vai trò mới thành công" });
    }

    // Sửa thông tin Role
    [HttpPut]
    public IActionResult Update(VaiTro obj)
    {
        if (!ModelState.IsValid) return BadRequest(ModelState);

        int ret = Provider.VaiTro.Update(obj);
        if (ret == -1) return NotFound(new { code = -1, message = "Không tìm thấy vai trò" });

        return Ok(new { code = ret, message = "Cập nhật vai trò thành công" });
    }

    // Xóa Role
    [HttpDelete("{id}")]
    public IActionResult Delete(short id)
    {
        int ret = Provider.VaiTro.Delete(id);
        if (ret == -1) return NotFound(new { code = -1, message = "Không tìm thấy vai trò" });
        if (ret == -2) return BadRequest(new { code = -2, message = "Không được phép xóa vai trò mặc định (Admin, Member)" });
        if (ret == -3) return BadRequest(new { code = -3, message = "Không thể xóa vì vẫn có người dùng thuộc vai trò này" });

        return Ok(new { code = ret, message = "Xóa vai trò thành công" });
    }
}
