# SportBooking giai đoạn 2

Database, dữ liệu mẫu, xác thực và phân quyền cho đề tài đặt sân thể thao và ghép kèo. Phát triển từ nguồn chuẩn `D:\LTDNT`, giữ cách tổ chức Controller → SiteProvider → Repository → DbContext. Flutter dùng các file đặt trực tiếp trong `lib`, không có thư mục Sports hoặc legacy. Backend dùng constructor thông thường, model/DTO dạng class riêng và hàm Controller có thân rõ ràng theo phong cách mẫu.

## Đã hoàn thành

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

## Phạm vi tiếp theo

Giai đoạn 3: CRUD danh mục, sân/dịch vụ và upload/xóa ảnh. Giai đoạn 4: danh sách sân, tìm kiếm, phân trang, lịch trống và giá. Sau đó triển khai giỏ, checkout, đơn hàng và ghép kèo. Stage2 mới tạo schema cho các module này, chưa công bố API đặt sân, thanh toán, QR hoặc ghép kèo. Email OTP cũng chưa triển khai.
