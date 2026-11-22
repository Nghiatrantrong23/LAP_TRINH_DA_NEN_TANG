using Microsoft.EntityFrameworkCore;

namespace WebApi.Models;

public class DonHangRepository : BaseRepository
{
    public static readonly Dictionary<string, (string Name, string Color)> StatusDefinitions = new()
    {
        { "ChoCoc", ("Chờ cọc", "#FF9800") },         // Orange
        { "DaXacNhan", ("Đã xác nhận", "#2196F3") },   // Blue
        { "DangChoi", ("Đang chơi", "#9C27B0") },     // Purple
        { "HoanThanh", ("Hoàn thành", "#4CAF50") },   // Green
        { "DaHuy", ("Đã hủy", "#F44336") }            // Red
    };

    public DonHangRepository(DatSanTheThaoContext context) : base(context)
    {
    }

    // Hiển thị danh sách đơn hàng + Tìm kiếm + Lọc theo ngày
    public IEnumerable<OrderDto> GetOrders(string? search, string? status, DateTime? fromDate, DateTime? toDate)
    {
        IQueryable<DonHang> query = context.DonHangs
            .Include(p => p.ChiTietDonHangs)
            .AsNoTracking();

        // 1. Tìm kiếm theo Số đơn hàng, Tên khách hàng hoặc Số điện thoại
        if (!string.IsNullOrWhiteSpace(search))
        {
            string s = search.Trim().ToLower();
            query = query.Where(p => p.SoDonHang.ToLower().Contains(s)
                                  || p.TenKhachHang.ToLower().Contains(s)
                                  || p.SoDienThoaiKhach.ToLower().Contains(s));
        }

        // 2. Lọc theo trạng thái
        if (!string.IsNullOrWhiteSpace(status) && !status.Equals("ALL", StringComparison.OrdinalIgnoreCase))
        {
            query = query.Where(p => p.TrangThai == status);
        }

        // 3. Lọc theo ngày đặt chơi
        if (fromDate.HasValue)
        {
            DateOnly from = DateOnly.FromDateTime(fromDate.Value.Date);
            query = query.Where(p => p.NgayDatChoi >= from);
        }

        if (toDate.HasValue)
        {
            DateOnly to = DateOnly.FromDateTime(toDate.Value.Date);
            query = query.Where(p => p.NgayDatChoi <= to);
        }

        var list = query.OrderByDescending(p => p.NgayTao).ToList();

        return list.Select(p => MapToDto(p));
    }

    // Lấy chi tiết đơn hàng
    public OrderDto? GetOrder(Guid id)
    {
        var order = context.DonHangs
            .Include(p => p.ChiTietDonHangs)
            .AsNoTracking()
            .FirstOrDefault(p => p.MaDonHang == id);

        return order is null ? null : MapToDto(order);
    }

    // Cập nhật trạng thái đơn hàng + Ghi nhật ký vào LichSuTrangThaiDon
    public int UpdateStatus(Guid orderId, string newStatus, Guid? changedBy, string? reason)
    {
        if (!StatusDefinitions.ContainsKey(newStatus))
            return -2; // Trạng thái không hợp lệ

        var order = context.DonHangs.FirstOrDefault(p => p.MaDonHang == orderId);
        if (order is null) return -1; // Không tìm thấy đơn hàng

        string oldStatus = order.TrangThai;
        order.TrangThai = newStatus;
        order.NgayCapNhat = DateTime.UtcNow;

        var history = new LichSuTrangThaiDon
        {
            MaDonHang = orderId,
            TrangThaiCu = oldStatus,
            TrangThaiMoi = newStatus,
            NguoiThayDoi = changedBy,
            LyDo = string.IsNullOrWhiteSpace(reason) ? $"Admin cập nhật trạng thái sang {newStatus}" : reason.Trim(),
            NgayTao = DateTime.UtcNow
        };

        context.LichSuTrangThaiDons.Add(history);
        return context.SaveChanges();
    }

    // Lấy danh sách các trạng thái có sẵn để hiển thị bộ lọc/dropdown
    public static List<OrderStatusDefinitionDto> GetStatusDefinitions()
    {
        return StatusDefinitions.Select(p => new OrderStatusDefinitionDto
        {
            Code = p.Key,
            Name = p.Value.Name,
            Color = p.Value.Color
        }).ToList();
    }

    private static OrderDto MapToDto(DonHang p)
    {
        string statusText = StatusDefinitions.TryGetValue(p.TrangThai, out var def) ? def.Name : p.TrangThai;

        return new OrderDto
        {
            MaDonHang = p.MaDonHang,
            SoDonHang = p.SoDonHang,
            MaThanhVien = p.MaThanhVien,
            MaCoSo = p.MaCoSo,
            NgayDatChoi = p.NgayDatChoi.ToString("yyyy-MM-dd"),
            TenKhachHang = p.TenKhachHang,
            SoDienThoaiKhach = p.SoDienThoaiKhach,
            TrangThai = p.TrangThai,
            TrangThaiText = statusText,
            TongTien = p.TongTien,
            TienCoc = p.TienCoc,
            GhiChu = p.GhiChu,
            NgayTao = p.NgayTao,
            NgayCapNhat = p.NgayCapNhat,
            SoLuongMatHang = p.ChiTietDonHangs?.Count ?? 0,
            ChiTiet = p.ChiTietDonHangs?.Select(d => new OrderItemDto
            {
                MaChiTietDon = d.MaChiTietDon,
                MaSanPham = d.MaSanPham,
                TenSanPham = d.TenSanPham,
                LoaiSanPham = d.LoaiSanPham,
                DonViTinh = d.DonViTinh,
                SoLuong = d.SoLuong,
                DonGia = d.DonGia,
                ThanhTien = d.ThanhTien
            }).ToList() ?? new List<OrderItemDto>()
        };
    }
}

