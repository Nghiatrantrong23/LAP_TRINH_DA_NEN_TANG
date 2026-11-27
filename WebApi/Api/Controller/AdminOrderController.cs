using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using WebApi.Models;

namespace WebApi.Api.Controller;

[Authorize(Roles = "Admin"), ApiController, Route("api/admin/order")]
public class AdminOrderController : BaseController
{
    [HttpGet]
    public async Task<IActionResult> GetOrders(
        [FromQuery] string? search,
        [FromQuery] string? status,
        [FromQuery] DateTime? fromDate,
        [FromQuery] DateTime? toDate)
    {
        var orders = await Provider.Order.GetOrdersAsync(search, status, fromDate, toDate);
        return Ok(orders);
    }

    [HttpGet("{id:guid}")]
    public async Task<IActionResult> GetOrder(Guid id)
    {
        var order = await Provider.Order.GetOrderAsync(id);
        if (order is null)
        {
            return NotFound(new { message = "Không tìm thấy đơn hàng" });
        }
        return Ok(order);
    }

    [HttpPut("{id:guid}/status")]
    public async Task<IActionResult> UpdateStatus(Guid id, [FromBody] UpdateOrderStatusModel model)
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

        int ret = await Provider.Order.UpdateStatusAsync(id, model.TrangThai.Trim(), adminId, model.LyDo);
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

    [HttpGet("statuses")]
    public IActionResult GetStatuses()
    {
        return Ok(OrderRepository.GetStatusDefinitions());
    }
}
