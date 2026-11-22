using Microsoft.EntityFrameworkCore;

namespace WebApi.Models;

public class OrderRepository : BaseRepository
{
    public static readonly Dictionary<string, (string DbStatus, string Name, string Color)> StatusMapping = new(StringComparer.OrdinalIgnoreCase)
    {
        { "ChoCoc", ("PendingDeposit", "Chờ cọc", "#FF9800") },
        { "PendingDeposit", ("PendingDeposit", "Chờ cọc", "#FF9800") },
        { "DaXacNhan", ("Confirmed", "Đã xác nhận", "#2196F3") },
        { "Confirmed", ("Confirmed", "Đã xác nhận", "#2196F3") },
        { "DangChoi", ("Playing", "Đang chơi", "#9C27B0") },
        { "Playing", ("Playing", "Đang chơi", "#9C27B0") },
        { "HoanThanh", ("Completed", "Hoàn thành", "#4CAF50") },
        { "Completed", ("Completed", "Hoàn thành", "#4CAF50") },
        { "DaHuy", ("Cancelled", "Đã hủy", "#F44336") },
        { "Cancelled", ("Cancelled", "Đã hủy", "#F44336") }
    };

    public OrderRepository(SportsBookingContext dbContext) : base(dbContext)
    {
    }

    public async Task<IEnumerable<OrderDto>> GetOrdersAsync(string? search, string? status, DateTime? fromDate, DateTime? toDate)
    {
        IQueryable<Order> query = context.Orders.AsNoTracking();

        if (!string.IsNullOrWhiteSpace(search))
        {
            string s = search.Trim().ToLower();
            query = query.Where(p => p.OrderCode.ToLower().Contains(s)
                                  || p.CustomerName.ToLower().Contains(s)
                                  || p.CustomerPhone.ToLower().Contains(s));
        }

        if (!string.IsNullOrWhiteSpace(status) && !status.Equals("ALL", StringComparison.OrdinalIgnoreCase))
        {
            string dbStatus = StatusMapping.TryGetValue(status, out var m) ? m.DbStatus : status;
            query = query.Where(p => p.Status == dbStatus);
        }

        if (fromDate.HasValue)
        {
            DateOnly from = DateOnly.FromDateTime(fromDate.Value.Date);
            query = query.Where(p => p.BookingDate >= from);
        }

        if (toDate.HasValue)
        {
            DateOnly to = DateOnly.FromDateTime(toDate.Value.Date);
            query = query.Where(p => p.BookingDate <= to);
        }

        var orders = await query.OrderByDescending(p => p.CreatedAt).ToListAsync();
        var orderIds = orders.Select(o => o.Id).ToList();

        var items = await context.OrderItems
            .AsNoTracking()
            .Where(i => orderIds.Contains(i.OrderId))
            .ToListAsync();

        var itemsByOrder = items.GroupBy(i => i.OrderId).ToDictionary(g => g.Key, g => g.ToList());

        return orders.Select(o => MapToDto(o, itemsByOrder.GetValueOrDefault(o.Id) ?? new List<OrderItem>()));
    }

    public async Task<OrderDto?> GetOrderAsync(Guid id)
    {
        var order = await context.Orders.AsNoTracking().FirstOrDefaultAsync(p => p.Id == id);
        if (order == null) return null;

        var items = await context.OrderItems.AsNoTracking().Where(i => i.OrderId == id).ToListAsync();
        return MapToDto(order, items);
    }

    public async Task<int> UpdateStatusAsync(Guid orderId, string newStatus, Guid? changedBy, string? reason)
    {
        if (!StatusMapping.TryGetValue(newStatus, out var mapping))
            return -2; // Trạng thái không hợp lệ

        var order = await context.Orders.FirstOrDefaultAsync(p => p.Id == orderId);
        if (order == null) return -1; // Không tìm thấy đơn hàng

        string oldStatus = order.Status;
        order.Status = mapping.DbStatus;
        order.UpdatedAt = DateTime.UtcNow;

        var history = new OrderStatusHistory
        {
            OrderId = orderId,
            FromStatus = oldStatus,
            ToStatus = mapping.DbStatus,
            ChangedByMemberId = changedBy,
            Reason = string.IsNullOrWhiteSpace(reason) ? $"Admin cập nhật trạng thái sang {mapping.Name}" : reason.Trim(),
            CreatedAt = DateTime.UtcNow
        };

        context.OrderStatusHistories.Add(history);
        return await context.SaveChangesAsync();
    }

    public static List<OrderStatusDefinitionDto> GetStatusDefinitions()
    {
        return new List<OrderStatusDefinitionDto>
        {
            new() { Code = "ChoCoc", Name = "Chờ cọc", Color = "#FF9800" },
            new() { Code = "DaXacNhan", Name = "Đã xác nhận", Color = "#2196F3" },
            new() { Code = "DangChoi", Name = "Đang chơi", Color = "#9C27B0" },
            new() { Code = "HoanThanh", Name = "Hoàn thành", Color = "#4CAF50" },
            new() { Code = "DaHuy", Name = "Đã hủy", Color = "#F44336" }
        };
    }

    private static OrderDto MapToDto(Order o, List<OrderItem> items)
    {
        string statusText = StatusMapping.TryGetValue(o.Status, out var def) ? def.Name : o.Status;
        string clientCode = (o.Status == "PendingDeposit") ? "ChoCoc" :
                            (o.Status == "Confirmed") ? "DaXacNhan" :
                            (o.Status == "Playing") ? "DangChoi" :
                            (o.Status == "Completed") ? "HoanThanh" :
                            (o.Status == "Cancelled") ? "DaHuy" : o.Status;

        return new OrderDto
        {
            MaDonHang = o.Id,
            SoDonHang = o.OrderCode,
            MaThanhVien = o.MemberId,
            MaCoSo = o.VenueId,
            NgayDatChoi = o.BookingDate.ToString("yyyy-MM-dd"),
            TenKhachHang = o.CustomerName,
            SoDienThoaiKhach = o.CustomerPhone,
            TrangThai = clientCode,
            TrangThaiText = statusText,
            TongTien = o.TotalAmount,
            TienCoc = o.DepositAmount,
            GhiChu = o.Note,
            NgayTao = o.CreatedAt,
            NgayCapNhat = o.UpdatedAt,
            SoLuongMatHang = items.Count,
            ChiTiet = items.Select(d => new OrderItemDto
            {
                MaChiTietDon = d.Id,
                MaSanPham = d.ProductId,
                TenSanPham = d.ProductName,
                LoaiSanPham = d.ProductType == "Court" ? "San" : (d.ProductType == "Service" ? "DichVu" : d.ProductType),
                DonViTinh = d.Unit,
                SoLuong = d.Quantity,
                DonGia = d.UnitPrice,
                ThanhTien = d.LineTotal
            }).ToList()
        };
    }
}
