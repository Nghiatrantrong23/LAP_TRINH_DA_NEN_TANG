# ĐỀ TÀI: ĐẶT SÂN THỂ THAO & DỊCH VỤ ĐI KÈM
## PHÂN HỆ: NHÓM XÁC THỰC NGƯỜI DÙNG (DATABASE: DatSanTheThao)

---

### BẢNG ĐỐI CHIẾU CHỨC NĂNG & ĐIỂM SỐ

| STT | Chức năng | Yêu cầu | Điểm | Vị trí cài đặt (Flutter / Backend / Database) |
|---|---|---|---|---|
| 1 | **Đăng ký người dùng** | Bắt buộc | 0.25đ | `register_page.dart` / `AuthController.Register` / Bảng `ThanhVien` |
| 2 | **Đăng nhập** | Bắt buộc | 0.25đ | `login_page.dart` / `AuthController.Login` / Bảng `ThanhVien`, `PhienDangNhap` |
| 3 | **Đổi mật khẩu** | Bắt buộc | 0.25đ | `change_password_page.dart` / `AuthController.ChangePassword` / Bảng `ThanhVien` |
| 4 | **Quản lý member** | Bắt buộc | 0.25đ | `member_management_page.dart` / `MemberController` / Cột `BiKhoa` bảng `ThanhVien` |
| 5 | **Quản lý role người dùng** | Bắt buộc | 0.50đ | `role_management_page.dart` / `RoleController` / Bảng `VaiTro` |
| 6 | **Chức năng thoát (logout)** | Bắt buộc | 0.25đ | `home_page.dart (_logout)` / `SessionHelper.delete()` |
| 7 | **Phân quyền (Member và Admin)** | Bắt buộc | 0.50đ | `home_page.dart` (phân chia UI) / `[Authorize(Roles = "Admin")]` trong WebApi |
| 8 | **Dùng Web API backend** | Bắt buộc | 0.75đ | Tầng `WebApi` (ASP.NET Core RESTful API + JWT Bearer + Refresh Token) |
| 9 | **Xác thực người dùng qua email (OTP)** | Điểm cộng | 0.50đ | `verify_email_page.dart` / `AuthController.VerifyEmail` / Bảng `MaXacThucEmail` (hash SHA256) |
| 10 | **Quên mật khẩu (OTP qua email)** | Điểm cộng | 0.50đ | `forgot_password_page.dart` / `AuthController.ForgotPassword` / Bảng `MaXacThucEmail` |
| 11 | **Đăng nhập Gmail, Facebook, Zalo** | Điểm cộng | 1.50đ (3 * 0.5đ) | `login_page.dart (_onExternalLogin)` / `AuthController.ExternalLogin` |

> 🎯 **Tổng điểm đạt được**: **3.0 điểm bắt buộc** (2.25đ chức năng + 0.75đ API) + **2.5 điểm cộng** = **5.5 điểm tuyệt đối**.

---

### MÔ HÌNH DỮ LIỆU ĐÃ ÁP DỤNG (`DatSanTheThao.sql`)
1. **`VaiTro`**:
   * `MaVaiTro` (SMALLINT, PK): 1 = Admin, 2 = Member.
   * `TenVaiTro` (VARCHAR(20), UNIQUE).
2. **`ThanhVien`**:
   * `MaThanhVien` (UNIQUEIDENTIFIER, PK).
   * `MaVaiTro` (SMALLINT, FK -> VaiTro).
   * `Ten`, `Ho`, `Email`, `EmailChuanHoa` (chống trùng lặp email hoa/thường).
   * `SoDienThoai`, `MatKhauHash` (mã hóa BCrypt).
   * `BiKhoa` (BIT: 0 = Hoạt động, 1 = Bị khóa).
   * `DaXacThucEmail` (BIT: 0 = Chưa xác thực, 1 = Đã xác thực).
   * `PhienBanBaoMat` (INT: tăng lên khi đổi mật khẩu để thu hồi token cũ).
   * `RowVersion` (ROWVERSION: chống xung đột dữ liệu đồng thời).
3. **`MaXacThucEmail`**:
   * `MaYeuCau` (UNIQUEIDENTIFIER, PK).
   * `MaThanhVien` (FK -> ThanhVien).
   * `MucDich` ('XacThucEmail' | 'QuenMatKhau').
   * `MaCodeHash` (BINARY(32): lưu hash SHA256 của mã OTP 6 số).
   * `HetHanLuc`, `DaDungLuc`, `SoLanSai` (chống brute-force mã OTP).
4. **`PhienDangNhap`**:
   * `MaPhien` (UNIQUEIDENTIFIER, PK).
   * `MaThanhVien` (FK -> ThanhVien).
   * `RefreshTokenHash` (BINARY(32): lưu hash SHA256 của Refresh Token).
   * `HetHanLuc`, `ThuHoiLuc`.

---

### HƯỚNG DẪN CHẠY DỰ ÁN

#### 1. Cơ sở dữ liệu:
* Mở **SQL Server Management Studio (SSMS)**.
* Mở và thực thi file: `Database/DatSanTheThao.sql`.
* Tài khoản mẫu được khởi tạo sẵn (Mật khẩu: `Password123@`):
  * **Admin**: `admin@datsanthethao.com`
  * **Member**: `member@datsanthethao.com`

#### 2. Khởi chạy Backend Web API:
```powershell
cd "d:\lap_Trinh_App\danentang\Nhóm xác thực người dùng\WebApi"
dotnet run
```
* Dịch vụ chạy tại `http://localhost:5109`.

#### 3. Khởi chạy Ứng dụng Di động Flutter:
```powershell
cd "d:\lap_Trinh_App\danentang\Nhóm xác thực người dùng\sport_booking_app"
flutter run
```
*(Lưu ý: Nếu chạy trên Android Emulator, chỉnh `API_URL=http://10.0.2.2:5109` trong file `.env`)*.
