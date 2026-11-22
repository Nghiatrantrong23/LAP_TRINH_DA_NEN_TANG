using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using WebApi.Models;

namespace WebApi.Api.Controllers;

// Quản lý đơn hàng (Admin)
// 1. Hiển thị danh sách đơn hàng (Bắt buộc - 0.25đ)
// 2. Cập nhật trạng thái đơn hàng (Bắt buộc - 0.50đ)
// 3. Tìm kiếm đơn hàng (Điểm cộng - 0.25đ)
// 4. Lọc đơn hàng theo ngày (Điểm cộng - 0.25đ)
// 5. Kết nối Web API (0.25đ)
[Authorize(Roles = "Admin"), ApiController, Route("api/[controller]")]
public class OrderController : BaseController
{
    // Lấy danh sách đơn hàng (kèm tìm kiếm + lọc theo trạng thái và ngày)
    [HttpGet]
    public IActionResult GetOrders(
        [FromQuery] string? search,
        [FromQuery] string? status,
        [FromQuery] DateTime? fromDate,
        [FromQuery] DateTime? toDate)
    {
        var orders = Provider.DonHang.GetOrders(search, status, fromDate, toDate);
        return Ok(orders);
    }

    // Xem chi tiết đơn hàng kèm danh sách chi tiết (Sân & Dịch vụ)
    [HttpGet("{id}")]
    public IActionResult GetOrder(Guid id)
    {
        var order = Provider.DonHang.GetOrder(id);
        if (order is null)
        {
            return NotFound(new { message = "Không tìm thấy đơn hàng" });
        }
        return Ok(order);
    }

    // Cập nhật trạng thái đơn hàng (ChoCoc, DaXacNhan, DangChoi, HoanThanh, DaHuy)
    [HttpPut("{id}/status")]
    public IActionResult UpdateStatus(Guid id, [FromBody] UpdateOrderStatusModel model)
    {
        if (string.IsNullOrWhiteSpace(model.TrangThai))
        {
            return BadRequest(new { message = "Trạng thái mới không được để trống" });
        }

        Guid? adminId = null;
        var claim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        if (Guid.TryParse(claim, out var parsed))
        {
            adminId = parsed;
        }

        int ret = Provider.DonHang.UpdateStatus(id, model.TrangThai.Trim(), adminId, model.LyDo);
        if (ret == -1)
        {
            return NotFound(new { code = -1, message = "Không tìm thấy đơn hàng cần cập nhật" });
        }
        if (ret == -2)
        {
            return BadRequest(new { code = -2, message = "Trạng thái không hợp lệ. Chỉ chấp nhận: ChoCoc, DaXacNhan, DangChoi, HoanThanh, DaHuy" });
        }

        return Ok(new
        {
            code = 1,
            message = "Cập nhật trạng thái đơn hàng thành công",
            newStatus = model.TrangThai
        });
    }

    // Danh sách định nghĩa các trạng thái đơn hàng
    [HttpGet("statuses")]
    public IActionResult GetStatuses()
    {
        return Ok(DonHangRepository.GetStatusDefinitions());
    }
}

