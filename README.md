# SportBooking — Ứng dụng Đặt sân thể thao Đa nền tảng

Ứng dụng đặt sân thể thao hoàn chỉnh phát triển trên nền tảng **ASP.NET Core 8 Web API** và **Flutter (Dart 3.13)**. 
Dự án được hợp nhất và tổ chức theo kiến trúc chuẩn: Controller → SiteProvider → Repository → DbContext.

---

## Cấu trúc thư mục dự án

```text
D:\LTDNT\
├── WebApi/                  # Backend ASP.NET Core 8 Web API (chạy port 5290)
│   ├── Api/Controller/      # Các Controller (Auth, Admin, Sân bãi, Đơn hàng)
│   ├── Models/              # DbContext, Entities, Repositories, DTOs
│   └── Services/            # EmailService, DatabaseSeeder, FileStorage
│
├── trek_bikes_app/          # Frontend Flutter Mobile/Web
│   └── lib/                 # Toàn bộ mã nguồn UI, Model, Repo (xem trek_bikes_app/lib/README.md)
│
├── database/                # Scripts cơ sở dữ liệu
│   ├── SportsBooking.sql    # Schema database SportsBookingStage2
│   └── TrekBikes.sql        # Schema Trek Bikes gốc
│
├── docs/                    # Tài liệu và báo cáo tích hợp
│   ├── INTEGRATION_REPORT.md # Báo cáo chi tiết đối chiếu 31 chức năng rubric
│   ├── API-STAGE2.md        # Tài liệu API xác thực & tài khoản
│   └── API-STAGE3.md        # Tài liệu API danh mục & sân bãi
│
├── _references/             # Mã nguồn tham khảo từ các nhóm và PR trước
│   ├── Nhom_xac_thuc_nguoi_dung/ # Tham khảo Social Login, OTP
│   └── Nhom_quan_ly_don_hang/    # Tham khảo nghiệp vụ đơn hàng Trek Bikes gốc
│
├── tests/                   # Các kịch bản kiểm thử tự động
├── setup.ps1                # Script khởi tạo nhanh môi trường và database
└── README.md
```

---

## Mới trong giai đoạn 3 & Tích hợp Quản lý đơn hàng

- **Quản lý đơn hàng (Admin)**: Hiển thị danh sách đơn, xem chi tiết, tìm kiếm theo tên/SĐT/mã đơn, lọc theo ngày, lọc theo trạng thái (`PendingDeposit`, `Confirmed`, `Playing`, `Completed`, `Cancelled`), cập nhật trạng thái có lưu vết lịch sử `OrderStatusHistory`.
- **Admin danh mục & sân bãi**: Thêm, sửa, xóa danh mục; upload ảnh sân; thiết lập sức chứa, giờ mở cửa, giá giờ vàng theo khung giờ.
- **Xác thực JWT + Refresh Token**: Đăng nhập, đăng ký, đổi mật khẩu, phân quyền Member/Admin.

- Admin thêm, sửa, xóa danh mục; ảnh đại diện tùy chọn. Chặn xóa khi danh mục còn sản phẩm, kể cả sản phẩm đã ngừng hoạt động.
- Admin quản lý sân và dịch vụ với tìm kiếm/phân trang. Sản phẩm mới bắt buộc upload ảnh; cập nhật có thể giữ ảnh cũ hoặc thay ảnh mới.
- Cấu hình sức chứa, mặt sân, trong nhà/ngoài trời, giờ mở cửa và giá giờ vàng. Form hiện áp dụng cùng cấu hình cho bảy ngày trong tuần, mốc giờ theo bước 30 phút.
- Chặn xóa sản phẩm có trong giỏ hoặc đơn, giữ lịch sử giá đã đặt. Sân có đơn chưa kết thúc không được ngừng hoạt động hoặc đổi giờ mở cửa, cơ sở, sức chứa.
- Sản phẩm/danh mục ngừng hoạt động được ẩn khỏi API công khai; Admin vẫn xem và sửa được.
- Các thao tác sửa/xóa dùng rowversion, ngăn ghi đè chỉnh sửa mới. Loại Court/Service không đổi sau khi tạo.
- Ảnh PNG/JPEG/WebP tối đa 5 MB, kiểm tra chữ ký file, tên ngẫu nhiên và giới hạn đường dẫn trong thư mục upload.
- Worker dọn ảnh chạy mỗi 5 giây. Xóa ảnh cũ được ghi cùng transaction cập nhật/xóa dữ liệu; lỗi I/O có backoff thử lại. Upload chưa được gắn vào bản ghi có job dọn sau 24 giờ để xử lý trường hợp tiến trình bị dừng đột ngột.
- Khi cập nhật thất bại, ảnh mới được dọn bù; worker kiểm tra ảnh còn được tham chiếu trước khi xóa. Không xóa ảnh đang dùng.

Đăng nhập Admin, chọn **Quản lý danh mục** hoặc **Quản lý sân & dịch vụ** trên trang chủ. Xem request/response tại [API-STAGE3.md](API-STAGE3.md). Mã vẫn theo Controller → SiteProvider → Repository → DbContext; Flutter dùng file trực tiếp trong lib.

Giai đoạn 3 dùng các bảng đã tạo ở giai đoạn 2, không thay schema và không cần migration mới. File ảnh upload nằm trong `WebApi/wwwroot/uploads`, không được commit/đưa vào ZIP mã nguồn. Khi sao lưu dữ liệu triển khai, cần sao lưu database và thư mục ảnh cùng nhau.

## Nền tảng giai đoạn 2 đã giữ lại

- Migration EF Core đầu tiên và SQL script idempotent cho 23 bảng của thiết kế giai đoạn 1.
- Database riêng `SportsBookingStage2`. Không thay đổi database TrekBikes hoặc bản SportBooking MVP trước đó.
- Seed hai Role Member/Admin, một Admin cấu hình riêng, một cơ sở, bốn danh mục, ba sân, hai dịch vụ, lịch mở cửa và giá giờ vàng cho các ngày trong tuần.
- Đăng ký mặc định Member; không nhận quyền, trạng thái khóa hoặc ID do người đăng ký gửi lên.
- Đăng nhập JWT 15 phút; refresh token tối đa 30 ngày, lưu hash trong database và xoay token sau mỗi lần sử dụng.
- Đăng xuất thu hồi phiên hiện tại; đổi mật khẩu thu hồi tất cả phiên. Khóa hoặc đổi quyền tài khoản thu hồi phiên cũ.
- Hồ sơ cá nhân; Admin xem/tìm kiếm/phân trang thành viên, sửa hồ sơ, khóa/mở khóa và gán Role.
- Chặn tự khóa/hạ quyền Admin, bảo vệ Admin hoạt động cuối cùng; cập nhật dùng rowversion để tránh ghi đè thay đổi mới.
- Flutter có đăng ký, đăng nhập, hồ sơ, đổi mật khẩu, quản lý thành viên; tự thử refresh một lần khi access token hết hạn và gộp các yêu cầu refresh đồng thời.

## Chạy dự án

Cần .NET SDK 8, Flutter có Dart 3.13 trở lên và SQL Server. Mặc định dùng Windows Authentication, SQL Server tại localhost.

Từ thư mục gốc:

```powershell
.\setup.ps1
```

Nếu PowerShell chặn thực thi script, chạy một lần:

```powershell
powershell -ExecutionPolicy Bypass -File .\setup.ps1
```

Setup tạo cấu hình riêng, khóa JWT và mật khẩu Admin ngẫu nhiên; chạy migration và seed. Đọc tài khoản trong `LOCAL-ADMIN.txt`. Các file riêng đều bị Git và bản ZIP loại trừ.

Nếu SQL Server dùng instance khác, sao chép `WebApi/appsettings.example.json` thành `WebApi/appsettings.json`, chỉnh chuỗi kết nối rồi chạy setup. Các giá trị bắt đầu bằng `SET_` sẽ được thay bằng bí mật ngẫu nhiên. Khi dùng lại database đã có Admin, giữ mật khẩu ban đầu; seed không đặt lại mật khẩu hay tự nâng quyền tài khoản cũ.

Terminal 1:

```powershell
dotnet run --project WebApi --no-launch-profile --urls http://localhost:5290
```

Terminal 2:

```powershell
cd trek_bikes_app
flutter pub get
flutter run -d chrome --web-port 7360
```

- API health: `http://localhost:5290/health`.
- Web: `http://localhost:7360`; CORS cho phép đúng origin này.
- Android Emulator: đặt `.env` thành `API_URL=http://10.0.2.2:5290`.
- Điện thoại: dùng IP LAN của máy chạy API và cấu hình listener/firewall phù hợp.
- HTTP chỉ được bật cho Android debug; khi triển khai thật cấu hình HTTPS.
- Windows hiện cần bật Developer Mode nếu Flutter báo không tạo được symlink. Bản Android chưa được build/xác minh ở giai đoạn này; SDK hiện có trên máy bị giới hạn quyền ghi.

## Cấu trúc theo mẫu

```text
WebApi/
  Api/Controller/
    BaseController.cs
    AuthController.cs
    MemberController.cs
    AdminMemberController.cs
    RoleController.cs
    CategoryController.cs
  Models/
    BaseProvider.cs
    BaseRepository.cs
    SiteProvider.cs
    SportsBookingContext.cs
    AuthRepository.cs
    MemberRepository.cs
    CategoryRepository.cs
    RegisterModel.cs, LoginModel.cs, LoginResponse.cs, ...
    Member.cs, Role.cs, AuthSession.cs, ...
  Services/
    Helper.cs
    DatabaseSeeder.cs
    BusinessException.cs
  Migrations/
    InitialSportsBooking + Designer + ModelSnapshot
  Program.cs

trek_bikes_app/lib/
  main.dart
  api_client.dart
  member.dart
  login.dart
  login_response.dart
  member_repository.dart
  session_helper.dart
  home_page.dart
  login_page.dart
  register_page.dart
  profile_page.dart
  change_password_page.dart
  admin_member_page.dart
  helper.dart
```

`AuthController.Register` gọi `Provider.Auth.Register`; `AdminMemberController` gọi `Provider.Member`; các Repository nhận `SportsBookingContext` qua `BaseRepository`. Helper xử lý token, chuẩn hóa email và DTO; không thay Repository bằng tầng nghiệp vụ khác.

Các file xe đạp không dùng trong bản Stage2 đã được loại khỏi bản làm việc. Mã nguồn được cập nhật trực tiếp tại `D:\LTDNT`; bản gốc trước cập nhật đã sao lưu trong `Documents\SportBooking-Update`. Lịch sử Git gốc vẫn giữ để đối chiếu. `TrekBikes.sql` là script mẫu tham khảo; `SportsBooking.sql` là schema mới.

## Database và migration

23 bảng gồm:

- Tài khoản: Roles, Members, AuthSessions, EmailChallenges.
- Danh mục/sân: Venues, Categories, Products, CourtProfiles, CourtSchedules, CourtPriceRules, CourtSlots.
- Đặt sân: Carts, CartItems, Orders, OrderItems, OrderItemSlots, SlotReservations, OrderStatusHistories, CheckInTokens, Payments.
- Ghép kèo: MatchRooms, MatchRequests.
- File ảnh: FileDeletionJobs.

Khóa chính CourtSlotId của SlotReservations dành cho chống đặt trùng ở giai đoạn checkout. Các bảng tương lai đã có PK/FK, unique index, ràng buộc cơ bản, kiểu tiền decimal(18,2) và rowversion cho dữ liệu cần kiểm tra cập nhật đồng thời. Kiểm tra nghiệp vụ như khớp sân với danh mục, giá chồng thời gian, sức chứa kèo sẽ được triển khai trong Repository của module tương ứng.

`SportsBooking.sql` tạo schema và migration history trên database được chọn; không chứa mật khẩu Admin hoặc seed tài khoản. Cách khởi tạo chuẩn là setup hoặc `--init-db` để migration và seed chạy cùng nhau.

Sau khi sửa entity cho giai đoạn tiếp theo:

```powershell
dotnet tool restore
dotnet ef migrations add TenThayDoi --project WebApi
dotnet ef database update --project WebApi
dotnet ef migrations script --idempotent --project WebApi --output SportsBooking.sql
```

Dừng API trước khi build trên Windows để tránh file thực thi đang bị khóa. Không dùng EnsureCreated và không xóa database để nâng cấp schema.

## API và kiểm thử

Xem `API-STAGE2.md` để biết request/response và quyền truy cập.

```powershell
dotnet build WebApi
cd trek_bikes_app
flutter analyze
flutter test
flutter build web --no-pub --no-wasm-dry-run
cd ..
python tests\auth_smoke.py
```

Kiểm thử API cần API đang chạy tại localhost:5290 và cấu hình Admin riêng. Chỉ chạy trên database phát triển `SportsBookingStage2`: script tạo tài khoản TEST theo mã lượt chạy và dọn đúng tài khoản đó. Nếu bị ngắt, chạy `tests/database_checks.ps1 -Mode Cleanup -RunTag <mã-lượt-10-ký-tự>` để dọn.

Giới hạn auth là 40 yêu cầu/phút/IP cho đăng ký, đăng nhập và refresh. Khi chạy bộ kiểm thử nhiều lần liên tiếp, đợi sang cửa sổ một phút nếu nhận HTTP 429. Kiểm thử bao gồm schema, seed chạy lặp, refresh token đồng thời, phiên theo thiết bị, thu hồi phiên, phân quyền và rowversion.

## Kiểm thử giai đoạn 3

```powershell
python tests\catalog_smoke.py
```

API cần đang chạy tại localhost:5290. Bộ kiểm thử dùng dữ liệu TEST3 theo mã lượt chạy, có fixture giỏ/đơn để kiểm tra ràng buộc và xác minh file ảnh vật lý. Script chỉ hỗ trợ database phát triển SportsBookingStage2; không chạy trên dữ liệu thật. Kết thúc sẽ dọn đúng bản ghi và ảnh của lượt chạy. Nếu bị ngắt, dùng `tests/catalog_fixture.ps1 -Mode Cleanup -RunTag <mã-lượt-10-ký-tự>` để dọn.

## Phạm vi tiếp theo

Giai đoạn 4 triển khai giao diện khách xem danh sách/chi tiết sân, tìm kiếm, phân trang và lịch trống. Sau đó triển khai giỏ, checkout chống trùng, đơn hàng, QR và ghép kèo. API đọc danh sách/chi tiết sản phẩm đã có để dùng tiếp; Stage3 chưa có giao diện đặt sân hoặc API checkout. Email OTP và thanh toán tự động cũng chưa triển khai.
