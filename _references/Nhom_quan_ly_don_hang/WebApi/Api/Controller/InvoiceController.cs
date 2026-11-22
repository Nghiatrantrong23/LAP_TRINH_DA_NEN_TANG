using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using WebApi.Api.Controller;
using WebApi.Models;

// Quản lý đơn hàng (Admin)
// 1. Hiển thị danh sách đơn hàng (Bắt buộc - 0.25đ)
// 2. Cập nhật trạng thái đơn hàng (Bắt buộc - 0.50đ)
// 3. Tìm kiếm đơn hàng (Điểm cộng - 0.25đ)
// 4. Lọc đơn hàng theo ngày (Điểm cộng - 0.25đ)
// 5. Kết nối Web API (0.25đ)
[Authorize]
[ApiController, Route("api/[controller]")]
public class InvoiceController : BaseController
{
    // Lấy danh sách hóa đơn (hỗ trợ tìm kiếm, lọc theo ngày, lọc theo trạng thái)
    [HttpGet]
    public IEnumerable<Invoice> GetInvoices(
        [FromQuery] string? search,
        [FromQuery] DateTime? fromDate,
        [FromQuery] DateTime? toDate,
        [FromQuery] int? statusId)
    {
        return Provider.Invoice.GetInvoices(search, fromDate, toDate, statusId);
    }

    // Cập nhật trạng thái đơn hàng (1: Cancel, 2: Waiting, 3: Accepted, 4: Shipping, 5: Finished)
    [HttpPut("status")]
    public int Update([FromQuery] long id, [FromQuery] short statusId)
    {
        return Provider.Invoice.Update(id, statusId);
    }

    // Xem chi tiết một đơn hàng kèm các mặt hàng (InvoiceDetails)
    [HttpGet("details/{id}")]
    public Invoice? GetInvoice(long id)
    {
        return Provider.Invoice.GetInvoice(id);
    }

    [HttpPost]
    public int Add(Invoice obj)
    {
        string? memberId = User.FindFirstValue(ClaimTypes.NameIdentifier);
        if (!string.IsNullOrEmpty(memberId))
        {
            obj.MemberId = memberId;
            return Provider.Invoice.Add(obj);
        }
        return -1;
    }
}