# Trek Bikes

Ứng dụng bán xe đạp gồm Flutter, ASP.NET Core Web API và SQL Server.

- `trek_bikes_app/`: ứng dụng Flutter.
- `WebApi/`: ASP.NET Core Web API (.NET 8).
- `TrekBikes.sql`: script tạo database và dữ liệu mẫu.

## Chạy Web API

1. Chạy `TrekBikes.sql` trên SQL Server để tạo database.
2. Sao chép `WebApi/appsettings.example.json` thành `WebApi/appsettings.json`.
3. Cập nhật chuỗi kết nối và đặt `Jwt:SecretKey` thành khóa ngẫu nhiên riêng, tối thiểu 32 ký tự.
4. Chạy:

```powershell
cd WebApi
dotnet restore
dotnet run --launch-profile http
```

API mặc định chạy tại `http://localhost:5283`.

## Chạy Flutter

Sao chép `trek_bikes_app/.env.example` thành `trek_bikes_app/.env`, sau đó chỉnh `API_URL` theo địa chỉ API. Trên Android Emulator, dùng `http://10.0.2.2:5283`; trên thiết bị thật, dùng IP LAN của máy chạy API.

```powershell
cd trek_bikes_app
flutter pub get
flutter run
```

Cấu hình cục bộ (`.env`, `WebApi/appsettings.json`) và file build được loại khỏi Git.

---

## Phân hệ: Quản lý đơn hàng (Admin)

### Bảng đối chiếu chức năng & điểm số

| STT | Chức năng | Phân loại | Điểm | Vị trí cài đặt (Flutter / Backend Web API / Database) |
|---|---|---|---|---|
| 1 | **Hiển thị danh sách đơn hàng** | Bắt buộc | **0.25đ** | `invoice_page.dart`, `invoice_details_page.dart` / `InvoiceController.GetInvoices` / Bảng `Invoice`, `InvoiceDetails` |
| 2 | **Cập nhật trạng thái đơn hàng** | Bắt buộc | **0.50đ** | Dialog chọn trạng thái trong `invoice_page.dart` / `InvoiceController.Update` (`PUT /api/invoice/status`) / Bảng `Invoice`, `Status` |
| 3 | **Tìm kiếm đơn hàng** | Điểm cộng | **0.25đ** | TextField tìm kiếm trong `invoice_page.dart` / `InvoiceRepository.GetInvoices` (tìm theo `InvoiceId` hoặc `MemberId`) |
| 4 | **Lọc đơn hàng theo ngày** | Điểm cộng | **0.25đ** | Chip bộ lọc trong `invoice_page.dart` (*All, Today, Last 7 Days, Custom Range*) / `InvoiceRepository.GetInvoices` (lọc theo `InvoiceDate`) |
| 5 | **Dùng Web API backend** | Bắt buộc | **0.25đ** | `InvoiceController.cs` (RESTful API `[Authorize]`, kết nối `InvoiceRepository` & `TrekBikesContext`) |

> 🎯 **Tổng điểm đạt được cho phân hệ Quản lý đơn hàng (Admin): 1.50 / 1.50 điểm (0.75đ bắt buộc + 0.50đ cộng + 0.25đ API)**.

### Dữ liệu mẫu (Seed Data)
* **Tài khoản Admin**: `admin@trekbikes.com` / `Password123@` (MemberId: `admin01`)
* **Tài khoản Khách hàng**: `john@trekbikes.com` / `Password123@` (MemberId: `john01`), `sarah@trekbikes.com` / `Password123@` (MemberId: `sarah01`)
* **Mẫu 5 đơn hàng**: Mã 1001 (Waiting), 1002 (Accepted), 1003 (Shipping), 1004 (Finished), 1005 (Cancel) tương ứng với các khoảng ngày và sản phẩm khác nhau.

