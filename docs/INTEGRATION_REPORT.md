# INTEGRATION REPORT — Sport Booking App
> Ngày tạo: 2026-11-22 | Branch: `integration/sport-booking` | Repo: https://github.com/Nghiatrantrong23/LAP_TRINH_DA_NEN_TANG

---

## 1. Tổng quan

Mục tiêu: Hợp nhất code từ nhiều nhánh thành **một ứng dụng đặt sân thể thao** duy nhất.

| Thành phần | Công nghệ | DB | Port |
|---|---|---|---|
| Backend API | ASP.NET Core **8.0** | SQL Server `SportsBookingStage2` | 5290 |
| Mobile App | Flutter / Dart 3.13 | (kết nối qua API) | — |
| Auth | JWT + Refresh Token | Members, Roles tables | — |

---

## 2. Phân tích nhánh

### 2.1 Các nhánh đã kiểm tra

| Nhánh | Nội dung chính | Tương thích |
|---|---|---|
| `main` | Trek Bikes gốc (Flutter + ASP.NET) | ✅ Tham khảo kiến trúc |
| `feature/sportbooking-stage2` | DB schema v2, Auth JWT | ✅ Đã merge vào stage3 |
| `feature/sportbooking-stage3` | CRUD danh mục, sân/dịch vụ, upload ảnh, Worker | ✅ **BASE BRANCH** |
| `Nhóm-xác-thực-người-dùng` | Auth OTP, Social Login, Quản lý đơn hàng (DatSanTheThao DB, .NET 10) | ⚠️ Không tương thích trực tiếp |
| `integration/sport-booking` | Branch tích hợp hiện tại | ✅ ACTIVE |

### 2.2 Nhánh `Nhóm-xác-thực-người-dùng` — Phân tích chi tiết

- **DB:** `DatSanTheThao` với field tiếng Việt (`DonHang`, `ThanhVien`, `VaiTro`)
- **.NET target:** `net10.0` — không build được với SDK 8.0.425 hiện có
- **Package app:** `sport_booking_app` (tên khác với `trek_bikes_app`)
- **Quyết định:** Không ghép DB, không ghép hệ thống đăng nhập. Chỉ lấy logic nghiệp vụ làm tham khảo.
- **Đã merge:** Nội dung trong subfolder `Nhóm xác thực người dùng/` (commit `79b2eae`) — không ghi đè file nào trong WebApi/ hoặc trek_bikes_app/

---

## 3. Bảng file — Giữ / Chuyển đổi / Hợp nhất / Không dùng

### Backend (WebApi/)

| File | Trạng thái | Ghi chú |
|---|---|---|
| `Api/Controller/AuthController.cs` | ✅ GIỮ | JWT + Refresh Token, stage3 |
| `Api/Controller/MemberController.cs` | ✅ GIỮ | Quản lý member, stage3 |
| `Api/Controller/CategoryController.cs` | ✅ GIỮ | CRUD danh mục, stage3 |
| `Api/Controller/ProductController.cs` | ✅ GIỮ | CRUD sân/dịch vụ, upload ảnh, stage3 |
| `Api/Controller/AdminOrderController.cs` | ✅ MỚI THÊM | Quản lý đơn hàng Admin |
| `Models/SportsBookingContext.cs` | ✅ GIỮ | DB English fields, Orders/OrderItems/etc. |
| `Models/OrderDto.cs` | ✅ MỚI THÊM | DTO bridge Việt–Anh |
| `Models/OrderRepository.cs` | ✅ MỚI THÊM | Repository truy vấn Orders |
| `Models/SiteProvider.cs` | ✅ CẬP NHẬT | Thêm property `Order` |
| `Services/EmailService.cs` | ✅ MỚI THÊM | IEmailService + demo fallback |
| `Services/DatabaseSeeder.cs` | ✅ CẬP NHẬT | Thêm seed 2 đơn hàng mẫu |
| `Program.cs` | ✅ CẬP NHẬT | Đăng ký IEmailService |
| `Nhóm xác thực người dùng/` | ⚠️ THAM KHẢO | Subfolder riêng, không dùng trực tiếp |

### Flutter (trek_bikes_app/lib/)

| File | Trạng thái | Ghi chú |
|---|---|---|
| `main.dart` | ✅ CẬP NHẬT | Thêm route `/admin/order` |
| `home_page.dart` | ✅ CẬP NHẬT | Thêm nút "Quản lý đơn hàng" cho Admin |
| `order_model.dart` | ✅ MỚI THÊM | Model OrderModel, OrderItemModel |
| `order_repository.dart` | ✅ MỚI THÊM | Gọi API `api/admin/order` |
| `order_management_page.dart` | ✅ MỚI THÊM | UI: thống kê, tìm kiếm, lọc, danh sách, detail, cập nhật |
| `cart_page.dart`, `product_page.dart`, v.v. | ✅ GIỮ | Trek Bikes UI pages (tham khảo) |

---

## 4. Kiến trúc tích hợp

```
Flutter (trek_bikes_app)
    ↕ HTTP/JSON (JWT Bearer)
ASP.NET Core 8 WebApi (port 5290)
    └── AuthController     → AuthRepository      → SportsBookingContext
    └── MemberController   → MemberRepository    → SportsBookingContext
    └── CategoryController → CategoryRepository  → SportsBookingContext
    └── ProductController  → ProductRepository   → SportsBookingContext
    └── AdminOrderController → OrderRepository   → SportsBookingContext
                                                       ↕
                                               SQL Server: SportsBookingStage2
```

**Phong cách code:** Controller → SiteProvider → Repository → DbContext (nhất quán toàn project)

---

## 5. Database — SportsBookingStage2

### Tables hiện có

| Table | Mô tả |
|---|---|
| `Roles` | Member (1), Admin (2) |
| `Members` | Tài khoản người dùng, JWT, refresh token |
| `Venues` | Cơ sở thể thao |
| `Categories` | Danh mục sân/dịch vụ |
| `Products` | Sân (Court) + Dịch vụ (Service) |
| `CourtSchedules` | Lịch mở cửa theo ngày |
| `CourtPriceRules` | Bảng giá theo khung giờ |
| `Orders` | Đơn đặt sân |
| `OrderItems` | Chi tiết đơn hàng |
| `OrderStatusHistories` | Lịch sử thay đổi trạng thái |
| `Carts`, `CartItems` | Giỏ hàng |
| `EmailChallenges` | OTP xác thực email |

### Mapping trạng thái đơn hàng

| DB (English) | Client (Tiếng Việt) | Màu |
|---|---|---|
| `PendingDeposit` | `ChoCoc` / Chờ cọc | 🟠 #FF9800 |
| `Confirmed` | `DaXacNhan` / Đã xác nhận | 🔵 #2196F3 |
| `Playing` | `DangChoi` / Đang chơi | 🟣 #9C27B0 |
| `Completed` | `HoanThanh` / Hoàn thành | 🟢 #4CAF50 |
| `Cancelled` | `DaHuy` / Đã hủy | 🔴 #F44336 |

---

## 6. Đối chiếu Rubric 31 chức năng

### Nhóm Xác thực & Phân quyền

| STT | Chức năng | Trạng thái | Endpoint |
|---|---|---|---|
| 1 | Đăng ký người dùng | ✅ Hoàn thành | `POST /auth/register` |
| 2 | Đăng nhập | ✅ Hoàn thành | `POST /auth/login` |
| 3 | Đổi mật khẩu | ✅ Hoàn thành | `PUT /auth/change-password` |
| 4 | Đăng xuất | ✅ Hoàn thành | `POST /auth/logout` |
| 5 | JWT + Refresh Token | ✅ Hoàn thành | `POST /auth/refresh` |
| 6 | Phân quyền Member/Admin | ✅ Hoàn thành | `[Authorize(Roles="Admin")]` |
| 7 | Xác thực email OTP | ❓ Cần kiểm tra | Có `EmailChallenges` table |
| 8 | Quên mật khẩu OTP | ❓ Cần kiểm tra | — |
| 9 | Đăng nhập Gmail/Facebook/Zalo | ❌ Chưa có | Phase sau |

### Nhóm Quản lý Admin

| STT | Chức năng | Trạng thái | Endpoint |
|---|---|---|---|
| 10 | Quản lý thành viên | ✅ Hoàn thành | `GET/PUT /api/member` |
| 11 | Quản lý danh mục | ✅ Hoàn thành | `CRUD /api/category` |
| 12 | Quản lý sân/dịch vụ | ✅ Hoàn thành | `CRUD /api/product` |
| 13 | Upload ảnh sân | ✅ Hoàn thành | `POST /api/product/{id}/image` |
| 14 | Danh sách đơn hàng Admin | ✅ Hoàn thành | `GET /api/admin/order` |
| 15 | Chi tiết đơn hàng | ✅ Hoàn thành | `GET /api/admin/order/{id}` |
| 16 | Cập nhật trạng thái đơn | ✅ Hoàn thành | `PUT /api/admin/order/{id}/status` |
| 17 | Tìm kiếm đơn hàng | ✅ Hoàn thành | Query param `?search=` |
| 18 | Lọc đơn theo ngày | ✅ Hoàn thành | Query param `?from=&to=` |
| 19 | Lọc đơn theo trạng thái | ✅ Hoàn thành | Query param `?status=` |

### Nhóm Trải nghiệm Member

| STT | Chức năng | Trạng thái | Ghi chú |
|---|---|---|---|
| 20 | Xem danh sách sân | ✅ Hoàn thành | ProductPage Flutter |
| 21 | Xem chi tiết sân | ✅ Hoàn thành | ProductDetailPage Flutter |
| 22 | Thêm vào giỏ hàng | ✅ Hoàn thành | CartPage Flutter |
| 23 | Đặt sân (tạo đơn) | ❓ Cần kiểm tra | Cần `POST /api/order` cho Member |
| 24 | Xem lịch sử đặt sân | ❌ Chưa có | Cần `GET /api/order/my` |
| 25 | Hủy đơn | ❌ Chưa có | Cần `PUT /api/order/{id}/cancel` |

### Nhóm Thông tin

| STT | Chức năng | Trạng thái | Ghi chú |
|---|---|---|---|
| 26 | Thông tin cơ sở (Venue) | ✅ Hoàn thành | Seed data |
| 27 | Lịch trình sân theo ngày | ✅ Hoàn thành | CourtSchedules |
| 28 | Bảng giá theo khung giờ | ✅ Hoàn thành | CourtPriceRules |
| 29 | Thông báo email | ✅ Cơ bản | EmailService (demo fallback) |
| 30 | Thống kê Admin | ✅ Cơ bản | Tính từ Orders |
| 31 | Báo cáo doanh thu | ❌ Chưa có | Phase sau |

---

## 7. Kết quả tích hợp

### Commit graph (integration/sport-booking)

```
* c826765 feat(integration): order management - AdminOrderController, OrderRepository...
* 79b2eae Merge remote-tracking branch 'origin/Nhóm-xác-thực-người-dùng' (subfolder)
* 2f83094 Add stage 3 catalog CRUD and image lifecycle
* 49e72b4 Keep sample coding style
* 2f93c78 Implement stage 2 database and auth
* 27a8fd8 Initial commit: Trek Bikes Flutter app and ASP.NET Core API
```

### Build status

| Component | Build | Test |
|---|---|---|
| WebApi (ASP.NET 8) | ✅ 0 errors, 0 warnings | — |
| trek_bikes_app (Flutter) | ✅ pub get OK | flutter analyze (đang chạy) |
| DB migrations | ✅ Auto-migrate on startup | SportsBookingStage2 |

---

## 8. Hướng dẫn chạy project tích hợp

### Yêu cầu
- .NET SDK 8.0.425
- Flutter 3.x / Dart 3.13
- SQL Server (LocalDB hoặc Express)
- `appsettings.Development.json` với đủ connection string và Seed credentials

### Backend
```powershell
cd D:\LTDNT\WebApi
dotnet run
# Chạy tại http://localhost:5290
# API docs: http://localhost:5290/swagger
```

### Flutter
```powershell
cd D:\LTDNT\trek_bikes_app
flutter pub get
flutter run -d <device>
```

### Endpoints chính

| Method | URL | Mô tả | Auth |
|---|---|---|---|
| POST | `/auth/register` | Đăng ký | Public |
| POST | `/auth/login` | Đăng nhập | Public |
| GET | `/api/admin/order` | Danh sách đơn | Admin |
| GET | `/api/admin/order/{id}` | Chi tiết đơn | Admin |
| PUT | `/api/admin/order/{id}/status` | Cập nhật trạng thái | Admin |
| GET | `/api/admin/order/statuses` | Danh sách trạng thái | Admin |
| CRUD | `/api/category` | Quản lý danh mục | Admin |
| CRUD | `/api/product` | Quản lý sân/dịch vụ | Admin |

---

## 9. Rủi ro & Lưu ý

> [!WARNING]
> **Chưa merge vào main** — Branch `integration/sport-booking` cần kiểm thử end-to-end trước khi tạo PR vào main.

> [!CAUTION]
> **Không ghép DB** — `DatSanTheThao` (Nhóm xác thực, .NET 10) và `SportsBookingStage2` (stage3, .NET 8) là hai DB khác nhau. Chỉ dùng `SportsBookingStage2`.

> [!NOTE]
> **Social Login** (Google, Facebook, Zalo) chưa tích hợp — cần `Google.Apis.Auth` package và cấu hình OAuth secrets. Giữ cho phase sau.

> [!NOTE]
> **Member order flow** (tạo đơn, xem lịch sử, hủy đơn) chưa hoàn chỉnh. Hiện tại chỉ Admin quản lý đơn. Cần thêm `POST /api/order` và `GET /api/order/my`.

---

## 10. Các bước tiếp theo (Next Steps)

| Ưu tiên | Task | Mô tả |
|---|---|---|
| 🔴 Cao | Kiểm tra OTP endpoint | Xác nhận `AuthController` có `verify-email` và `forgot-password` chưa |
| 🔴 Cao | Member order flow | Thêm `POST /api/order` (tạo đơn) + `GET /api/order/my` (xem lịch sử) |
| 🟡 Trung | Hủy đơn Member | `PUT /api/order/{id}/cancel` với kiểm tra quyền |
| 🟡 Trung | Flutter test | `flutter test` + chạy thử trên thiết bị |
| 🟢 Thấp | Social Login | Google OAuth cho net8.0 (phase sau) |
| 🟢 Thấp | Báo cáo doanh thu | Dashboard Admin (phase sau) |
| 🟢 Thấp | Push integration branch | `git push origin integration/sport-booking` sau khi test OK |

---

*Tạo bởi: Antigravity Integration Agent | Repo: D:\LTDNT | Branch: integration/sport-booking*
