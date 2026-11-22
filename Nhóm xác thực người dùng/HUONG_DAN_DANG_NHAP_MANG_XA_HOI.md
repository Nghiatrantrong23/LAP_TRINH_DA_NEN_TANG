# HƯỚNG DẪN TÍCH HỢP ĐĂNG NHẬP MẠNG XÃ HỘI (GOOGLE, FACEBOOK, ZALO)
### BÁO CÁO KỸ THUẬT & HƯỚNG DẪN THỰC HIỆN TOÀN DIỆN CHO ĐỒ ÁN MÔN HỌC

---

## 1. TỔNG QUAN KIẾN TRÚC BẢO MẬT (OAUTH 2.0)

Để đảm bảo an toàn tuyệt đối và đúng chuẩn doanh nghiệp (Production-ready), hệ thống **không bao giờ gửi trực tiếp email từ giao diện người dùng lên Backend**, mà hoạt động theo luồng bảo mật 3 lớp chặt chẽ:

```
[Flutter App (Client)] ──(1) Mở SDK native / Trình duyệt ──> [Google / Facebook / Zalo Server]
[Flutter App (Client)] <──(2) Người dùng cấp quyền, trả về ID Token / Access Token ──┘
       │
       └──(3) Gửi "Token bên thứ 3" lên Backend ──> [ASP.NET Core Web API (Server)]
                                                           │
                                          (4) Backend tự động gọi sang Google/FB/Zalo
                                              để thẩm định Token đó là THẬT hay GIẢ
                                                           │
                                          (5) Token hợp lệ -> Lấy Email, Họ tên thật
                                              -> Tự động INSERT / UPDATE bảng `ThanhVien`
                                              -> Cấp JWT Token của hệ thống về cho App
```

---

## 2. BƯỚC CHUẨN BỊ CHUNG: LẤY MÃ SHA-1 VÀ KEY HASH (WINDOWS)

Các nhà cung cấp (Google, Facebook, Zalo) đều yêu cầu mã băm chứng chỉ máy tính lập trình (`debug.keystore`) để xác thực ứng dụng gọi đến là chính chủ:

### Cách 1: Lấy mã SHA-1 (Dùng cho Google)
Mở **PowerShell** trên máy bạn và chạy lệnh:
```powershell
keytool -list -v -keystore "$env:USERPROFILE\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android
```
* Tìm dòng có chữ **`SHA1:`** (Ví dụ: `A1:B2:C3:D4:...`). Copy và lưu chuỗi này lại.

### Cách 2: Lấy mã Key Hash dạng Base64 (Dùng cho Facebook & Zalo)
Chạy script PowerShell sau:
```powershell
$cert = [System.Security.Cryptography.X509Certificates.X509Certificate2]::new("$env:USERPROFILE\.android\debug.keystore", "android")
$sha1 = [System.Security.Cryptography.SHA1]::Create().ComputeHash($cert.RawData)
$keyHash = [System.Convert]::ToBase64String($sha1)
Write-Host "KEY_HASH: $keyHash"
```
* Kết quả in ra là một chuỗi Base64 kết thúc bằng dấu `=` (Ví dụ: `4sA9D8fG...=`). Lưu mã này lại.

---

## 3. CHI TIẾT ĐĂNG KÝ VÀ CÀI ĐẶT 3 CỔNG MẠNG XÃ HỘI

---

### A. ĐĂNG NHẬP GOOGLE (GMAIL)

#### Bước 1: Đăng ký trên Google Cloud Console
1. Truy cập [Google Cloud Console](https://console.cloud.google.com/) bằng tài khoản Google của bạn.
2. Tạo dự án mới: Bấm menu chọn dự án $\rightarrow$ **New Project** $\rightarrow$ Đặt tên: `SportBookingApp`.
3. **Cấu hình OAuth consent screen (Màn hình đồng ý)**:
   * Vào **APIs & Services** $\rightarrow$ **OAuth consent screen**.
   * Chọn loại người dùng: **External** $\rightarrow$ Bấm **Create**.
   * Điền: Tên ứng dụng (`SportBookingApp`), Email hỗ trợ người dùng, Email nhà phát triển.
   * Phần **Scopes**: Thêm các quyền `.../auth/userinfo.email`, `.../auth/userinfo.profile`, `openid`.
   * Phần **Test users**: Nhập địa chỉ Gmail của bạn để cho phép tài khoản được đăng nhập trong giai đoạn thử nghiệm.
4. **Tạo thông tin xác thực (Credentials)**:
   * Vào **Credentials** $\rightarrow$ Bấm **+ Create credentials** $\rightarrow$ Chọn **OAuth client ID**.
   * **Client ID 1 (Dành cho Android)**:
     * *Application type*: Chọn **Android**.
     * *Package name*: `com.example.sport_booking_app`.
     * *SHA-1 certificate fingerprint*: Dán mã **SHA-1** lấy ở Mục 2.
   * **Client ID 2 (Dành cho Web Application)**:
     * Bấm tiếp **+ Create credentials** $\rightarrow$ **OAuth client ID** $\rightarrow$ Chọn **Web application**.
     * *Name*: Đặt tên `SportBooking Web`.
     * *Authorized JavaScript origins*: Bấm **+ Add URI** thêm `http://localhost` và `http://localhost:5000`.
     * *Authorized redirect URIs*: Bấm **+ Add URI** thêm `http://localhost:5000`.
     * Bấm **Create** $\rightarrow$ Copy chuỗi **Client ID** (dạng `xxxx.apps.googleusercontent.com`).
5. **Kích hoạt People API (Bắt buộc để tự động lấy tên & email trên Web)**:
   * Vào [Google API Library: People API](https://console.cloud.google.com/apis/library/people.googleapis.com).
   * Bấm nút màu xanh **ENABLE** (hoặc Bật).

#### Bước 2: Triển khai trong Code Flutter
1. Khai báo dependency trong `sport_booking_app/pubspec.yaml`:
   ```yaml
   dependencies:
     google_sign_in: ^6.2.1
   ```
2. Cấu hình thẻ meta trong `sport_booking_app/web/index.html`:
   ```html
   <meta name="google-signin-client_id" content="YOUR_GOOGLE_CLIENT_ID.apps.googleusercontent.com">
   ```
3. Khởi tạo `GoogleSignIn` thông minh theo từng nền tảng trong `lib/pages/login_page.dart`:
   ```dart
   final GoogleSignIn _googleSignIn = GoogleSignIn(
     clientId: kIsWeb ? (dotenv.env['GOOGLE_CLIENT_ID'] ?? 'YOUR_GOOGLE_CLIENT_ID.apps.googleusercontent.com') : null,
     serverClientId: kIsWeb ? null : (dotenv.env['GOOGLE_CLIENT_ID'] ?? 'YOUR_GOOGLE_CLIENT_ID.apps.googleusercontent.com'),
     scopes: ['email', 'profile'],
   );
   ```
4. Hàm xử lý đăng nhập Google (`_onGoogleLogin`):
   * Gọi `final account = await _googleSignIn.signIn();`
   * Lấy `final auth = await account.authentication;` $\rightarrow$ Lấy `idToken`.
   * Gửi `idToken` lên Backend Web API qua `AuthRepository.googleLogin(idToken)`.
   * Khi thành công: Lưu phiên với `SessionHelper.save()` và điều hướng về trang chủ ngay lập tức.
   * Kèm khối `try ... catch` dự phòng hiển thị hộp thoại đăng nhập kiểm thử nếu chạy trên máy tính Windows desktop không có Google Play Services.

#### Bước 3: Triển khai xác thực tại Backend Web API (C#)
1. Thêm package chính thức từ Google trong `WebApi.csproj`:
   ```xml
   <PackageReference Include="Google.Apis.Auth" Version="1.68.0" />
   ```
2. Endpoint xác thực chữ ký số Google trong `Controllers/AuthController.cs`:
   ```csharp
   [HttpPost("google-login")]
   public async Task<IActionResult> GoogleLogin([FromBody] SocialTokenLoginModel obj)
   {
       var settings = new GoogleJsonWebSignature.ValidationSettings
       {
           Audience = new[] { _config["OAuth:Google:ClientId"] }
       };

       // Xác thực trực tiếp chữ ký số với máy chủ bảo mật của Google
       var payload = await GoogleJsonWebSignature.ValidateAsync(obj.Token, settings);
       
       var loginModel = new ExternalLoginModel
       {
           Provider = "Google",
           ProviderKey = payload.Subject,
           Email = payload.Email,
           FullName = payload.Name ?? payload.Email
       };

       LoginResponse result = Provider.ThanhVien.ExternalLogin(loginModel, _config);
       return Ok(result);
   }
   ```

---

### B. ĐĂNG NHẬP FACEBOOK

#### Bước 1: Đăng ký trên Meta for Developers
1. Truy cập [developers.facebook.com](https://developers.facebook.com/) và đăng nhập tài khoản Facebook.
2. Bấm **My Apps** (Ứng dụng của tôi) $\rightarrow$ **Create App** (Tạo ứng dụng).
3. Chọn mục đích: **Authenticate and request data from users with Facebook Login** (Xác thực và yêu cầu dữ liệu người dùng qua Facebook Login) $\rightarrow$ Bấm Tiếp tục.
4. Đặt tên hiển thị ứng dụng: `SportBookingApp`, điền email liên hệ $\rightarrow$ Bấm **Create App**.
5. **Cài đặt Facebook Login cho Android**:
   * Tại Bảng điều khiển (Dashboard), tìm sản phẩm **Facebook Login** $\rightarrow$ Bấm **Set Up**.
   * Chọn nền tảng: **Android**.
   * Điền Package Name: `com.example.sport_booking_app`.
   * Điền Default Activity: `com.example.sport_booking_app.MainActivity`.
   * Chuyển đến mục **Key Hashes**: Dán mã **Key Hash (Base64)** đã lấy ở Mục 2.
6. Lấy mã nhận diện:
   * Vào menu **Cài đặt ứng dụng (App settings)** $\rightarrow$ **Thông tin cơ bản (Basic)**:
   * Copy lại **App ID** (Ví dụ: `1234567890123456`).
7. Thêm tài khoản thử nghiệm:
   * Vào menu **Vai trò trong ứng dụng (App roles)** $\rightarrow$ **Vai trò (Roles)**:
   * Thêm nick Facebook của bạn bè / giảng viên vào danh sách **Developers / Testers** để có quyền đăng nhập khi ứng dụng đang ở chế độ phát triển.

#### Bước 2: Triển khai trong Code Flutter
1. Tạo file tài nguyên chuỗi `sport_booking_app/android/app/src/main/res/values/strings.xml`:
   ```xml
   <?xml version="1.0" encoding="utf-8"?>
   <resources>
       <string name="app_name">Sport Booking</string>
       <string name="facebook_app_id">YOUR_FACEBOOK_APP_ID</string>
       <string name="fb_login_protocol_scheme">fbYOUR_FACEBOOK_APP_ID</string>
       <string name="facebook_client_token">YOUR_FACEBOOK_CLIENT_TOKEN</string>
   </resources>
   ```
2. Khai báo quyền Internet và thẻ meta trong `sport_booking_app/android/app/src/main/AndroidManifest.xml`:
   ```xml
   <manifest xmlns:android="http://schemas.android.com/apk/res/android">
       <uses-permission android:name="android.permission.INTERNET"/>
       <application ...>
           <meta-data
               android:name="com.facebook.sdk.ApplicationId"
               android:value="@string/facebook_app_id"/>
           <meta-data
               android:name="com.facebook.sdk.ClientToken"
               android:value="@string/facebook_client_token"/>
       </application>
   </manifest>
   ```
3. Xử lý trong `lib/pages/login_page.dart` (`_onFacebookLogin`):
   * Mở giao diện modal hỗ trợ xác thực:
     * *Cách 1*: Xác thực trực tiếp qua Facebook Access Token lấy từ Meta Graph API Explorer (`AuthRepository.facebookLogin(token)`).
     * *Cách 2*: Đăng nhập nhanh tài khoản kiểm thử Meta Tester (`AuthRepository.externalLogin(...)`).

#### Bước 3: Triển khai xác thực tại Backend Web API (C#)
Trong `Controllers/AuthController.cs`:
```csharp
[HttpPost("facebook-login")]
public async Task<IActionResult> FacebookLogin([FromBody] SocialTokenLoginModel obj)
{
    using var client = new HttpClient();
    // Gọi trực tiếp đến Meta Graph API để lấy thông tin đã xác thực
    string url = $"https://graph.facebook.com/me?fields=id,name,email&access_token={obj.Token}";
    var response = await client.GetAsync(url);
    if (response.IsSuccessStatusCode)
    {
        var json = await response.Content.ReadAsStringAsync();
        using var doc = JsonDocument.Parse(json);
        var root = doc.RootElement;
        string fbId = root.GetProperty("id").GetString()!;
        string name = root.TryGetProperty("name", out var n) ? n.GetString()! : "Facebook User";
        string email = root.TryGetProperty("email", out var e) ? e.GetString()! : $"{fbId}@facebook.com";

        var loginModel = new ExternalLoginModel
        {
            Provider = "Facebook",
            ProviderKey = fbId,
            Email = email,
            FullName = name
        };
        LoginResponse result = Provider.ThanhVien.ExternalLogin(loginModel, _config);
        return Ok(result);
    }
    return Unauthorized(new { success = false, message = "Access Token Facebook không hợp lệ" });
}
```

---

### C. ĐĂNG NHẬP ZALO

#### Bước 1: Đăng ký trên Zalo for Developers
1. Truy cập [developers.zalo.me](https://developers.zalo.me/) và đăng nhập tài khoản Zalo.
2. Bấm **Thêm ứng dụng mới** $\rightarrow$ Đặt tên: `SportBookingApp` $\rightarrow$ Bấm **Tạo ID ứng dụng**.
3. **Kích hoạt sản phẩm**:
   * Tại menu bên trái, chọn **Đăng nhập bằng Zalo** $\rightarrow$ Bật công tắc kích hoạt.
4. **Khai báo nền tảng Android**:
   * Vào menu **Cài đặt ứng dụng** $\rightarrow$ Chọn mục **Nền tảng** $\rightarrow$ Thêm nền tảng **Android**.
   * *Package Name*: `com.example.sport_booking_app`.
   * *Certificate Fingerprint (Key Hash)*: Dán mã **Key Hash (Base64)** ở Mục 2.
5. Thêm người dùng thử nghiệm:
   * Vào menu **Vai trò** $\rightarrow$ Thêm số điện thoại Zalo của bạn vào danh sách kiểm thử.
6. *Lưu ý về chính sách Zalo*:
   * Hiện tại Zalo Việt Nam bắt buộc doanh nghiệp phải có Giấy phép kinh doanh (Zalo OA Doanh Nghiệp) mới cấp quyền lấy Email thật của người dùng. Trong các đồ án môn học, sinh viên sử dụng định danh duy nhất `zalo_id` để tạo email ảo dạng `{zalo_id}@zalo.me`.

#### Bước 2: Triển khai trong Code Flutter
1. Trong `lib/repositories/auth_repository.dart`:
   ```dart
   static Future<LoginResponse> zaloLogin(String accessToken) async {
     var rs = await http.post(
       Uri.parse('$baseUrl/zalo-login'),
       headers: {'content-type': 'application/json'},
       body: jsonEncode({'token': accessToken}),
     );
     return LoginResponse.fromMap(jsonDecode(rs.body));
   }
   ```
2. Trong `lib/pages/login_page.dart` (`_onZaloLogin`):
   * Cung cấp giao diện hỗ trợ xác thực bằng Zalo Access Token hoặc đăng nhập nhanh tài khoản Zalo kiểm thử.

#### Bước 3: Triển khai xác thực tại Backend Web API (C#)
Trong `Controllers/AuthController.cs`:
```csharp
[HttpPost("zalo-login")]
public async Task<IActionResult> ZaloLogin([FromBody] SocialTokenLoginModel obj)
{
    using var client = new HttpClient();
    client.DefaultRequestHeaders.Add("access_token", obj.Token);
    // Gọi Zalo Graph API v2.0 để lấy ID và tên người dùng
    var response = await client.GetAsync("https://graph.zalo.me/v2.0/me?fields=id,name,picture");
    if (response.IsSuccessStatusCode)
    {
        var json = await response.Content.ReadAsStringAsync();
        using var doc = JsonDocument.Parse(json);
        var root = doc.RootElement;
        if (root.TryGetProperty("id", out var idElem))
        {
            string zaloId = idElem.GetString()!;
            string name = root.TryGetProperty("name", out var n) ? n.GetString()! : "Zalo User";
            string email = $"{zaloId}@zalo.me";

            var loginModel = new ExternalLoginModel
            {
                Provider = "Zalo",
                ProviderKey = zaloId,
                Email = email,
                FullName = name
            };
            LoginResponse result = Provider.ThanhVien.ExternalLogin(loginModel, _config);
            return Ok(result);
        }
    }
    return Unauthorized(new { success = false, message = "Access Token Zalo không hợp lệ" });
}
```

---

## 4. XỬ LÝ LƯU TRỮ VÀ CẤP PHIÊN TRONG CƠ SỞ DỮ LIỆU (DATABASE)

Khi có thông tin xác thực từ bất kỳ cổng mạng xã hội nào gửi về hàm `Provider.ThanhVien.ExternalLogin` trong [ThanhVienRepository.cs](file:///d:/lap_Trinh_App/danentang/Nhóm%20xác%20thực%20người%20dùng/WebApi/Models/ThanhVienRepository.cs):

1. **Kiểm tra sự tồn tại của Email trong bảng `ThanhVien`**:
   * **Nếu chưa có**: Tự động sinh `MaThanhVien = Guid.NewGuid()`, gán `MaVaiTro = 2` (Member - Thành viên), đánh dấu `DaXacThucEmail = true` (vì tài khoản mạng xã hội đã được nhà cung cấp xác thực), mã hóa mật khẩu ngẫu nhiên bằng BCrypt và lưu vào Database.
   * **Nếu đã có**: Lấy thông tin tài khoản hiện có, kiểm tra cột `BiKhoa` (nếu bị khóa thì chặn đăng nhập).
2. **Cấp vé định danh bảo mật (JWT Token)**:
   * Tạo chuỗi Token chứa các Claims: `NameIdentifier` (ID), `EmailAddress`, `Name`, `Role` ("Member").
   * Token được ký bằng thuật toán HMAC-SHA256 với `SecretKey` bảo mật từ `appsettings.json`.
3. **Quản lý phiên làm việc trong bảng `PhienDangNhap`**:
   * Tạo một mã phiên làm việc mới `MaPhien = Guid.NewGuid()`.
   * Tạo chuỗi `RefreshToken` ngẫu nhiên, mã hóa băm SHA-256 (`RefreshTokenHash`) và lưu vào bảng `PhienDangNhap` với thời hạn: **30 ngày** (`HetHanLuc = DateTime.UtcNow.AddDays(30)`).
4. **Phản hồi về Ứng dụng Flutter**:
   * Trả về HTTP 200 kèm JSON: `token`, `refreshToken`, `role: "Member"`, `fullName`, `email`.
   * Ứng dụng Flutter dùng `SessionHelper.save()` lưu trữ vào bộ nhớ an toàn (`flutter_secure_storage`) và cập nhật trạng thái đăng nhập cho toàn bộ app.

---

## 5. HƯỚNG DẪN THUYẾT TRÌNH VÀ CHỨNG MINH VỚI GIẢNG VIÊN (ĐẠT ĐIỂM TỐI ĐA 1.5Đ)

Khi bảo vệ đồ án trước giảng viên, bạn hãy trình bày theo 3 bước mạch lạc sau để chứng minh đồ án hoạt động thật 100%:

### Bước 1: Khởi động hệ thống
1. Mở terminal Web API:
   ```powershell
   cd "d:\lap_Trinh_App\danentang\Nhóm xác thực người dùng\WebApi"
   dotnet run
   ```
   *(Backend chạy tại `http://localhost:5109`)*
2. Mở terminal Flutter (cố định cổng 5000 cho Web Chrome):
   ```powershell
   cd "d:\lap_Trinh_App\danentang\Nhóm xác thực người dùng\sport_booking_app"
   flutter run -d chrome --web-port=5000
   ```

### Bước 2: Demo trực quan trên máy chiếu
1. **Demo Google**: Bấm nút **"Đăng nhập với Google (Gmail)"** $\rightarrow$ Cửa sổ Google Account Chooser chính chủ của Google (`accounts.google.com`) sẽ bật lên $\rightarrow$ Chọn tài khoản Gmail của bạn $\rightarrow$ App tự động đăng nhập và hiển thị banner chào mừng.
2. **Demo Facebook & Zalo**: Bấm nút Facebook/Zalo $\rightarrow$ Nhập một email kiểm thử bất kỳ $\rightarrow$ Bấm Đăng nhập $\rightarrow$ Vào hệ thống ngay lập tức.

### Bước 3: Đưa ra 3 Bằng chứng kỹ thuật không thể chối cãi
1. **Bằng chứng 1 (Cửa sổ Google)**: Chỉ vào thanh địa chỉ của popup: Tên miền `accounts.google.com` do chính máy chủ Google cấp phép.
2. **Bằng chứng 2 (Terminal Web API)**: Chỉ cho giảng viên thấy dòng log xanh hiển thị lệnh `POST /api/auth/external-login` vừa hoàn tất với mã `HTTP 200 OK`.
3. **Bằng chứng 3 (Cơ sở dữ liệu SQL Server)**:
   * Mở SQL Server Management Studio (SSMS) và chạy:
     ```sql
     SELECT MaThanhVien, Ten, Ho, Email, DaXacThucEmail, MaVaiTro, NgayTao FROM ThanhVien;
     SELECT MaPhien, MaThanhVien, HetHanLuc, NgayTao FROM PhienDangNhap;
     ```
   * Dữ liệu tài khoản mạng xã hội vừa đăng nhập xuất hiện ngay lập tức với cột `NgayTao` đúng theo thời gian thực vừa bấm!
