using Microsoft.EntityFrameworkCore;
using WebApi.Services;

namespace WebApi.Models;

public class ThanhVienRepository : BaseRepository
{
    public ThanhVienRepository(DatSanTheThaoContext context) : base(context)
    {
    }

    public IEnumerable<ThanhVien> GetMembers()
    {
        return context.ThanhViens.Include(p => p.VaiTro).ToList();
    }

    public ThanhVien? GetMember(Guid id)
    {
        return context.ThanhViens.Include(p => p.VaiTro).FirstOrDefault(p => p.MaThanhVien == id);
    }

    public ThanhVien? GetMemberByEmail(string email)
    {
        string emailChuanHoa = email.Trim().ToUpper();
        return context.ThanhViens.Include(p => p.VaiTro).FirstOrDefault(p => p.EmailChuanHoa == emailChuanHoa);
    }

    // 1. Đăng ký người dùng mới (Lưu vào ThanhVien & tạo OTP hash vào MaXacThucEmail)
    public (int code, string? otp) Register(RegisterModel obj)
    {
        string emailChuanHoa = obj.Email.Trim().ToUpper();
        if (context.ThanhViens.Any(p => p.EmailChuanHoa == emailChuanHoa))
            return (-1, null); // Email đã tồn tại

        Guid maThanhVien = Guid.NewGuid();
        ThanhVien thanhVien = new ThanhVien
        {
            MaThanhVien = maThanhVien,
            MaVaiTro = 2, // Member
            Ten = obj.GivenName.Trim(),
            Ho = string.IsNullOrWhiteSpace(obj.Surname) ? "" : obj.Surname.Trim(),
            Email = obj.Email.Trim().ToLower(),
            EmailChuanHoa = emailChuanHoa,
            SoDienThoai = obj.Phone?.Trim(),
            MatKhauHash = Helper.HashPassword(obj.Password),
            BiKhoa = false,
            DaXacThucEmail = false,
            PhienBanBaoMat = 1,
            NgayTao = DateTime.UtcNow
        };

        context.ThanhViens.Add(thanhVien);

        // Tạo mã OTP 6 số và hash SHA256 lưu vào bảng MaXacThucEmail
        string otp = Helper.GenerateOtp(6);
        MaXacThucEmail maOtp = new MaXacThucEmail
        {
            MaYeuCau = Guid.NewGuid(),
            MaThanhVien = maThanhVien,
            MucDich = "XacThucEmail",
            MaCodeHash = Helper.ComputeHashSha256(otp),
            HetHanLuc = DateTime.UtcNow.AddMinutes(15),
            SoLanSai = 0,
            NgayTao = DateTime.UtcNow
        };
        context.MaXacThucEmails.Add(maOtp);

        int ret = context.SaveChanges();
        return (ret > 0 ? 1 : -2, otp);
    }

    // 2. Xác thực tài khoản qua OTP gửi về Email (Tra cứu từ bảng MaXacThucEmail)
    public int VerifyEmail(string email, string code)
    {
        ThanhVien? thanhVien = GetMemberByEmail(email);
        if (thanhVien is null) return -1; // Không tìm thấy email

        byte[] codeHash = Helper.ComputeHashSha256(code.Trim());

        // Lấy mã xác thực mới nhất chưa dùng và còn hạn
        MaXacThucEmail? maOtp = context.MaXacThucEmails
            .Where(p => p.MaThanhVien == thanhVien.MaThanhVien && p.MucDich == "XacThucEmail" && p.DaDungLuc == null && p.HetHanLuc >= DateTime.UtcNow)
            .OrderByDescending(p => p.NgayTao)
            .FirstOrDefault();

        if (maOtp is null) return -2; // Hết hạn hoặc không tồn tại yêu cầu

        if (maOtp.SoLanSai >= 5) return -3; // Đã nhập sai quá 5 lần

        if (!maOtp.MaCodeHash.SequenceEqual(codeHash))
        {
            maOtp.SoLanSai++;
            context.SaveChanges();
            return -2; // Mã không khớp
        }

        maOtp.DaDungLuc = DateTime.UtcNow;
        thanhVien.DaXacThucEmail = true;
        thanhVien.NgayCapNhat = DateTime.UtcNow;

        context.ThanhViens.Update(thanhVien);
        context.MaXacThucEmails.Update(maOtp);
        return context.SaveChanges();
    }

    // Gửi lại mã OTP xác thực
    public (int code, string? otp) ResendConfirmationCode(string email)
    {
        ThanhVien? thanhVien = GetMemberByEmail(email);
        if (thanhVien is null) return (-1, null);
        if (thanhVien.DaXacThucEmail) return (-3, null); // Đã xác thực rồi

        string otp = Helper.GenerateOtp(6);
        MaXacThucEmail maOtp = new MaXacThucEmail
        {
            MaYeuCau = Guid.NewGuid(),
            MaThanhVien = thanhVien.MaThanhVien,
            MucDich = "XacThucEmail",
            MaCodeHash = Helper.ComputeHashSha256(otp),
            HetHanLuc = DateTime.UtcNow.AddMinutes(15),
            SoLanSai = 0,
            NgayTao = DateTime.UtcNow
        };
        context.MaXacThucEmails.Add(maOtp);

        int ret = context.SaveChanges();
        return (ret > 0 ? 1 : -2, otp);
    }

    // 3. Đăng nhập (Kiểm tra BiKhoa, DaXacThucEmail, mật khẩu, và lưu PhienDangNhap RefreshToken)
    public LoginResponse Login(LoginModel obj, IConfiguration configuration)
    {
        ThanhVien? thanhVien = GetMemberByEmail(obj.Email);
        if (thanhVien is null)
        {
            return new LoginResponse { Success = false, Message = "Email không tồn tại trong hệ thống" };
        }

        if (thanhVien.BiKhoa)
        {
            return new LoginResponse { Success = false, Message = "Tài khoản của bạn đã bị khóa bởi Quản trị viên" };
        }

        if (!thanhVien.DaXacThucEmail)
        {
            return new LoginResponse
            {
                Success = false,
                Message = "Tài khoản chưa được xác thực email. Vui lòng nhập mã OTP để kích hoạt",
                Email = thanhVien.Email
            };
        }

        if (!Helper.VerifyPassword(obj.Password, thanhVien.MatKhauHash))
        {
            return new LoginResponse { Success = false, Message = "Mật khẩu không chính xác" };
        }

        // Sinh JWT Access Token
        string token = Helper.GenerateToken(thanhVien, configuration);

        // Sinh Refresh Token và lưu vào bảng PhienDangNhap
        string rawRefreshToken = Helper.GenerateRefreshToken();
        PhienDangNhap phien = new PhienDangNhap
        {
            MaPhien = Guid.NewGuid(),
            MaThanhVien = thanhVien.MaThanhVien,
            RefreshTokenHash = Helper.ComputeHashSha256(rawRefreshToken),
            HetHanLuc = DateTime.UtcNow.AddDays(30),
            NgayTao = DateTime.UtcNow
        };
        context.PhienDangNhaps.Add(phien);
        context.SaveChanges();

        string roleName = thanhVien.VaiTro?.TenVaiTro ?? (thanhVien.MaVaiTro == 1 ? "Admin" : "Member");
        string fullName = string.IsNullOrEmpty(thanhVien.Ho) ? thanhVien.Ten : $"{thanhVien.Ho} {thanhVien.Ten}";

        return new LoginResponse
        {
            Success = true,
            Message = "Đăng nhập thành công",
            Token = token,
            RefreshToken = rawRefreshToken,
            Role = roleName,
            Email = thanhVien.Email,
            FullName = fullName,
            MemberId = thanhVien.MaThanhVien.ToString()
        };
    }

    // 4. Đăng nhập liên kết mạng xã hội (Gmail, Facebook, Zalo)
    public LoginResponse ExternalLogin(ExternalLoginModel obj, IConfiguration configuration)
    {
        ThanhVien? thanhVien = GetMemberByEmail(obj.Email);

        if (thanhVien is null)
        {
            // Tách họ và tên từ FullName
            string fullName = obj.FullName.Trim();
            string ho = "";
            string ten = fullName;
            int lastSpace = fullName.LastIndexOf(' ');
            if (lastSpace > 0)
            {
                ho = fullName.Substring(0, lastSpace);
                ten = fullName.Substring(lastSpace + 1);
            }

            thanhVien = new ThanhVien
            {
                MaThanhVien = Guid.NewGuid(),
                MaVaiTro = 2, // Member
                Ten = ten,
                Ho = ho,
                Email = obj.Email.Trim().ToLower(),
                EmailChuanHoa = obj.Email.Trim().ToUpper(),
                MatKhauHash = Helper.HashPassword(Guid.NewGuid().ToString()), // Mật khẩu ngẫu nhiên
                BiKhoa = false,
                DaXacThucEmail = true, // Đã xác thực từ Google/FB/Zalo
                PhienBanBaoMat = 1,
                NgayTao = DateTime.UtcNow
            };

            context.ThanhViens.Add(thanhVien);
            context.SaveChanges();
            thanhVien = GetMember(thanhVien.MaThanhVien);
        }
        else
        {
            if (thanhVien.BiKhoa)
            {
                return new LoginResponse { Success = false, Message = "Tài khoản của bạn đã bị khóa" };
            }

            if (!thanhVien.DaXacThucEmail)
            {
                thanhVien.DaXacThucEmail = true;
                context.SaveChanges();
            }
        }

        string token = Helper.GenerateToken(thanhVien!, configuration);
        string rawRefreshToken = Helper.GenerateRefreshToken();
        PhienDangNhap phien = new PhienDangNhap
        {
            MaPhien = Guid.NewGuid(),
            MaThanhVien = thanhVien!.MaThanhVien,
            RefreshTokenHash = Helper.ComputeHashSha256(rawRefreshToken),
            HetHanLuc = DateTime.UtcNow.AddDays(30),
            NgayTao = DateTime.UtcNow
        };
        context.PhienDangNhaps.Add(phien);
        context.SaveChanges();

        string roleName = thanhVien!.VaiTro?.TenVaiTro ?? (thanhVien.MaVaiTro == 1 ? "Admin" : "Member");
        string name = string.IsNullOrEmpty(thanhVien.Ho) ? thanhVien.Ten : $"{thanhVien.Ho} {thanhVien.Ten}";

        return new LoginResponse
        {
            Success = true,
            Message = $"Đăng nhập thành công với {obj.Provider}",
            Token = token,
            RefreshToken = rawRefreshToken,
            Role = roleName,
            Email = thanhVien.Email,
            FullName = name,
            MemberId = thanhVien.MaThanhVien.ToString()
        };
    }

    // 5. Quên mật khẩu - Sinh mã OTP lưu vào MaXacThucEmail
    public (int code, string? otp) ForgotPassword(string email)
    {
        ThanhVien? thanhVien = GetMemberByEmail(email);
        if (thanhVien is null) return (-1, null);

        string otp = Helper.GenerateOtp(6);
        MaXacThucEmail maOtp = new MaXacThucEmail
        {
            MaYeuCau = Guid.NewGuid(),
            MaThanhVien = thanhVien.MaThanhVien,
            MucDich = "QuenMatKhau",
            MaCodeHash = Helper.ComputeHashSha256(otp),
            HetHanLuc = DateTime.UtcNow.AddMinutes(15),
            SoLanSai = 0,
            NgayTao = DateTime.UtcNow
        };
        context.MaXacThucEmails.Add(maOtp);

        int ret = context.SaveChanges();
        return (ret > 0 ? 1 : -2, otp);
    }

    // Đặt lại mật khẩu với OTP
    public int ResetPassword(ResetPasswordModel obj)
    {
        ThanhVien? thanhVien = GetMemberByEmail(obj.Email);
        if (thanhVien is null) return -1;

        byte[] codeHash = Helper.ComputeHashSha256(obj.Code.Trim());
        MaXacThucEmail? maOtp = context.MaXacThucEmails
            .Where(p => p.MaThanhVien == thanhVien.MaThanhVien && p.MucDich == "QuenMatKhau" && p.DaDungLuc == null && p.HetHanLuc >= DateTime.UtcNow)
            .OrderByDescending(p => p.NgayTao)
            .FirstOrDefault();

        if (maOtp is null) return -2;

        if (!maOtp.MaCodeHash.SequenceEqual(codeHash))
        {
            maOtp.SoLanSai++;
            context.SaveChanges();
            return -2;
        }

        maOtp.DaDungLuc = DateTime.UtcNow;
        thanhVien.MatKhauHash = Helper.HashPassword(obj.NewPassword);
        thanhVien.PhienBanBaoMat++; // Tăng bảo mật để vô hiệu hóa các token cũ
        thanhVien.NgayCapNhat = DateTime.UtcNow;

        context.ThanhViens.Update(thanhVien);
        context.MaXacThucEmails.Update(maOtp);
        return context.SaveChanges();
    }

    // 6. Đổi mật khẩu
    public int ChangePassword(Guid memberId, ChangePasswordModel obj)
    {
        ThanhVien? thanhVien = context.ThanhViens.Find(memberId);
        if (thanhVien is null) return -1;

        if (!Helper.VerifyPassword(obj.OldPassword, thanhVien.MatKhauHash))
            return -2; // Mật khẩu cũ không chính xác

        thanhVien.MatKhauHash = Helper.HashPassword(obj.NewPassword);
        thanhVien.PhienBanBaoMat++;
        thanhVien.NgayCapNhat = DateTime.UtcNow;
        context.ThanhViens.Update(thanhVien);
        return context.SaveChanges();
    }

    // Cập nhật hồ sơ cá nhân
    public int UpdateProfile(Guid memberId, UpdateProfileModel obj)
    {
        ThanhVien? thanhVien = context.ThanhViens.Find(memberId);
        if (thanhVien is null) return -1;

        thanhVien.Ten = obj.GivenName.Trim();
        thanhVien.Ho = string.IsNullOrWhiteSpace(obj.Surname) ? "" : obj.Surname.Trim();
        thanhVien.SoDienThoai = obj.Phone?.Trim();
        thanhVien.NgayCapNhat = DateTime.UtcNow;
        context.ThanhViens.Update(thanhVien);
        return context.SaveChanges();
    }

    // Khóa / Mở khóa tài khoản (Admin)
    public int ToggleStatus(Guid memberId)
    {
        ThanhVien? thanhVien = context.ThanhViens.Find(memberId);
        if (thanhVien is null) return -1;

        // Không cho khóa Admin hệ thống gốc
        if (thanhVien.MaVaiTro == 1 && thanhVien.Email == "admin@datsanthethao.com")
            return -2;

        thanhVien.BiKhoa = !thanhVien.BiKhoa;
        thanhVien.NgayCapNhat = DateTime.UtcNow;
        context.ThanhViens.Update(thanhVien);
        return context.SaveChanges();
    }

    // Phân quyền Role cho Member (Admin)
    public int ChangeRole(Guid memberId, short roleId)
    {
        ThanhVien? thanhVien = context.ThanhViens.Find(memberId);
        if (thanhVien is null) return -1;

        if (!context.VaiTros.Any(p => p.MaVaiTro == roleId))
            return -2; // Role không tồn tại

        thanhVien.MaVaiTro = roleId;
        thanhVien.NgayCapNhat = DateTime.UtcNow;
        context.ThanhViens.Update(thanhVien);
        return context.SaveChanges();
    }
}

