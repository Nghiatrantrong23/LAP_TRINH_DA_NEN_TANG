# Lưu trữ tài nguyên Trek Bikes (Legacy Archive)

Thư mục này được tách riêng hoàn toàn khỏi hệ thống ứng dụng chính để lưu trữ:
1. `TrekBikes.sql`: Cơ sở dữ liệu bán xe đạp Trek Bikes gốc.
2. `bikes/`: Toàn bộ hình ảnh xe đạp gốc.
3. `Nhom_quan_ly_don_hang/`: Mã nguồn của nhóm quản lý đơn hàng phát triển trên nền Trek Bikes (dùng Invoice, InvoiceDetails, BikeController...).

> [!NOTE]
> Toàn bộ logic nghiệp vụ quản lý đơn hàng của nhóm này đã được chuyển thể và tích hợp sang mô hình **Đặt sân thể thao (SportBooking)** trong `WebApi/` và `trek_bikes_app/` (sử dụng Order, OrderItem, SportsBookingContext).
