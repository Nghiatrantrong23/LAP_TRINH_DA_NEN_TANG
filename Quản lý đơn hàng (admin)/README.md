# PHÂN HỆ: QUẢN LÝ ĐƠN HÀNG (ADMIN)
## ĐỀ TÀI: ĐẶT SÂN THỂ THAO & DỊCH VỤ

---

### BẢNG ĐỐI CHIẾU CHỨC NĂNG & ĐIỂM SỐ (TỔNG 1.50 ĐIỂM)

| STT | Chức năng | Phân loại | Điểm | Vị trí cài đặt (Flutter / Backend Web API / Database) |
|---|---|---|---|---|
| 1 | **Hiển thị danh sách đơn hàng** | Bắt buộc | **0.25đ** | `order_management_page.dart` / `OrderController.GetOrders` (`GET /api/order`) / Bảng `DonHang`, `ChiTietDonHang` |
| 2 | **Cập nhật trạng thái đơn hàng** | Bắt buộc | **0.50đ** | Dialog cập nhật trạng thái trong `order_management_page.dart` / `OrderController.UpdateStatus` (`PUT /api/order/{id}/status`) / Bảng `DonHang`, `LichSuTrangThaiDon` |
| 3 | **Tìm kiếm đơn hàng** | Điểm cộng | **0.25đ** | TextField tìm kiếm trong `order_management_page.dart` / `DonHangRepository.GetOrders` (tìm theo `SoDonHang`, `TenKhachHang`, `SoDienThoaiKhach`) |
| 4 | **Lọc đơn hàng theo ngày** | Điểm cộng | **0.25đ** | Bộ lọc ngày trong `order_management_page.dart` (*Tất cả, Hôm nay, 7 ngày qua, Tùy chọn khoảng ngày*) / `DonHangRepository.GetOrders` (lọc theo `NgayDatChoi`) |
| 5 | **Dùng Web API backend** | Bắt buộc | **0.25đ** | `OrderController.cs` (RESTful API bảo vệ bằng `[Authorize(Roles = "Admin")]`, JWT Bearer Token) |

> 🎯 **Tổng điểm đạt được**: **0.75đ bắt buộc** + **0.50đ điểm cộng** + **0.25đ dùng API** = **1.50 điểm tuyệt đối**.

---

### CẤU TRÚC PHÂN HỆ

```
Quản lý đơn hàng (admin)/
├── README.md               # Tài liệu hướng dẫn & bảng điểm đối chiếu
├── WebApi/                 # Backend ASP.NET Core Web API (.NET 10)
│   ├── Api/Controllers/
│   │   ├── OrderController.cs      # API quản lý đơn hàng (Admin)
│   │   ├── AuthController.cs       # API xác thực & cấp JWT Token
│   │   ├── MemberController.cs     # API thành viên
│   │   └── RoleController.cs       # API vai trò
│   └── Models/
│       ├── DonHang.cs              # Entity DonHang, ChiTietDonHang, LichSuTrangThaiDon
│       ├── DonHangRepository.cs    # Repository xử lý truy vấn, tìm kiếm, lọc ngày, cập nhật trạng thái
│       ├── DatSanTheThaoContext.cs # DbContext
│       └── DTOs.cs                 # DTOs OrderDto, OrderItemDto, UpdateOrderStatusModel
└── sport_booking_app/      # Ứng dụng di động Flutter
    └── lib/
        ├── models/order_model.dart             # Model Order & OrderItem
        ├── repositories/order_repository.dart  # Kết nối Web API
        ├── pages/order_management_page.dart    # Giao diện Quản lý đơn hàng (Admin)
        ├── pages/home_page.dart                # Bảng điều khiển Admin có nút vào Quản lý đơn hàng
        └── main.dart                           # Route '/admin/orders'
```

---

### HƯỚNG DẪN KIỂM THỬ

#### 1. Tài khoản kiểm thử Admin:
* **Email**: `admin@datsanthethao.com`
* **Mật khẩu**: `Password123@`
* **Vai trò**: `Admin`

#### 2. Khởi chạy Backend Web API:
```powershell
cd "Quản lý đơn hàng (admin)\WebApi"
dotnet run
```
* API chạy tại: `http://localhost:5109`
* Endpoint danh sách đơn hàng: `GET http://localhost:5109/api/order`
* Endpoint cập nhật trạng thái: `PUT http://localhost:5109/api/order/{id}/status`

#### 3. Khởi chạy Ứng dụng Flutter:
```powershell
cd "Quản lý đơn hàng (admin)\sport_booking_app"
flutter run
```

#### 4. Trải nghiệm các chức năng:
1. Đăng nhập với tài khoản Admin (`admin@datsanthethao.com` / `Password123@`).
2. Tại màn hình chính Admin, bấm vào mục **"Quản lý đơn hàng (Orders)"**.
3. **Hiển thị danh sách**: Xem danh sách các đơn hàng, bấm "Chi tiết" để xem các mục sân & dịch vụ trong đơn.
4. **Cập nhật trạng thái**: Bấm "Đổi trạng thái", chọn trạng thái mới (`ChoCoc`, `DaXacNhan`, `DangChoi`, `HoanThanh`, `DaHuy`), nhập ghi chú và bấm lưu.
5. **Tìm kiếm**: Gõ mã đơn (ví dụ `DH-20261122`), tên khách hoặc SĐT vào ô tìm kiếm ở trên cùng.
6. **Lọc theo ngày**: Bấm các nút "Hôm nay", "7 ngày qua", hoặc "Tùy chọn..." để lọc theo khoảng ngày đặt chơi.
