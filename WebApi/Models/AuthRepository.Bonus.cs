using System.Data;
using System.Security.Cryptography;
using System.Text;
using Microsoft.EntityFrameworkCore;
using WebApi.Services;

namespace WebApi.Models;

public partial class AuthRepository
{
    private const string VerifyPurpose = "VerifyEmail";
    private const string ResetPurpose = "ResetPassword";

    public async Task SendVerificationEmail(Guid memberId, IEmailService emailService)
    {
        await using var tx = await context.Database.BeginTransactionAsync(IsolationLevel.ReadCommitted);
        var member = await LockMember(memberId);
        if (member is null || member.IsLocked)
            throw new BusinessException(403, "ACCOUNT_UNAVAILABLE", "Tài khoản không khả dụng.");
        if (member.EmailConfirmed)
        {
            await tx.CommitAsync();
            return;
        }
        var otp = await CreateChallenge(member.Id, VerifyPurpose)
            ?? throw new BusinessException(429, "OTP_COOLDOWN", "Vui lòng đợi một phút trước khi gửi lại mã.");
        await tx.CommitAsync();
        await SendOtp(emailService, member.Email, "Xác thực email SportBooking", otp);
    }

    public async Task VerifyEmail(Guid memberId, string otp)
    {
        await using var tx = await context.Database.BeginTransactionAsync(IsolationLevel.ReadCommitted);
        var member = await LockMember(memberId);
        if (member is null || member.IsLocked || member.EmailConfirmed)
            throw InvalidOtp();
        if (!await ConsumeChallenge(member.Id, VerifyPurpose, otp))
        {
            await tx.CommitAsync();
            throw InvalidOtp();
        }
        member.EmailConfirmed = true;
        member.UpdatedAt = DateTime.UtcNow;
        await context.SaveChangesAsync();
        await tx.CommitAsync();
    }

    public async Task ForgotPassword(string email, IEmailService emailService)
    {
        var normalized = Helper.NormalizeEmail(email);
        if (normalized.EndsWith("@SPORTBOOKING.INVALID", StringComparison.Ordinal)) return;
        await using var tx = await context.Database.BeginTransactionAsync(IsolationLevel.ReadCommitted);
        var member = await LockMemberByEmail(normalized);
        if (member is null || member.IsLocked) return;
        var otp = await CreateChallenge(member.Id, ResetPurpose);
        await tx.CommitAsync();
        // Do not reveal whether this email has an account, including on cooldown or SMTP failure.
        if (otp is not null)
            await emailService.SendOtpAsync(member.Email, "Đặt lại mật khẩu SportBooking", otp);
    }

    public async Task ResetPassword(ResetPasswordModel model)
    {
        Helper.ValidatePassword(model.NewPassword);
        var normalized = Helper.NormalizeEmail(model.Email);
        if (normalized.EndsWith("@SPORTBOOKING.INVALID", StringComparison.Ordinal)) throw InvalidOtp();
        await using var tx = await context.Database.BeginTransactionAsync(IsolationLevel.ReadCommitted);
        var member = await LockMemberByEmail(normalized);
        if (member is null || member.IsLocked) throw InvalidOtp();
        if (!await ConsumeChallenge(member.Id, ResetPurpose, model.Otp))
        {
            await tx.CommitAsync();
            throw InvalidOtp();
        }
        member.PasswordHash = BCrypt.Net.BCrypt.HashPassword(model.NewPassword);
        member.SecurityVersion++;
        member.UpdatedAt = DateTime.UtcNow;
        await context.AuthSessions.Where(x => x.MemberId == member.Id && x.RevokedAt == null)
            .ExecuteUpdateAsync(s => s.SetProperty(x => x.RevokedAt, DateTime.UtcNow));
        await context.SaveChangesAsync();
        await tx.CommitAsync();
    }

    public async Task<LoginResponse> ExternalLogin(ExternalLoginModel model)
    {
        var (slug, name, id) = model.Provider switch
        {
            "Google" => ("google", "Google Demo", Guid.Parse("A7C26306-9C54-4EEF-AD99-524EE00943CA")),
            "Facebook" => ("facebook", "Facebook Demo", Guid.Parse("21BE5911-1A37-4076-A93E-9320CD67D44E")),
            "Zalo" => ("zalo", "Zalo Demo", Guid.Parse("89118638-B81E-437D-B760-E63A2050FFB2")),
            _ => throw new BusinessException(400, "INVALID_PROVIDER", "Nhà cung cấp không được hỗ trợ.")
        };
        var email = $"{slug}@sportbooking.invalid";
        var normalized = Helper.NormalizeEmail(email);
        if (Helper.NormalizeEmail(model.Email) != normalized || model.ProviderKey != $"demo-{slug}" || model.Name != name)
            throw new BusinessException(400, "INVALID_DEMO_ACCOUNT", "Tài khoản demo không hợp lệ.");

        await using var tx = await context.Database.BeginTransactionAsync(IsolationLevel.Serializable);
        var member = await LockMemberByEmail(normalized);
        if (member is null)
        {
            member = new Member
            {
                Id = id, Email = email, NormalizedEmail = normalized, GivenName = name,
                EmailConfirmed = true, PasswordHash = BCrypt.Net.BCrypt.HashPassword(Helper.NewRefreshToken()[..32])
            };
            context.Members.Add(member);
            context.Carts.Add(new Cart { MemberId = member.Id });
        }
        if (member.Id != id || member.RoleId != 1 || member.IsLocked)
            throw new BusinessException(403, "ACCOUNT_UNAVAILABLE", "Tài khoản demo không khả dụng.");
        member.Role = await context.Roles.SingleAsync(x => x.Id == member.RoleId && x.Name == "Member");
        var result = await CreateSession(member);
        await tx.CommitAsync();
        return result;
    }

    private Task<Member?> LockMember(Guid id) => context.Members
        .FromSqlInterpolated($"SELECT * FROM Members WITH (UPDLOCK,HOLDLOCK) WHERE Id={id}").SingleOrDefaultAsync();

    private Task<Member?> LockMemberByEmail(string normalized) => context.Members
        .FromSqlInterpolated($"SELECT * FROM Members WITH (UPDLOCK,HOLDLOCK) WHERE NormalizedEmail={normalized}").SingleOrDefaultAsync();

    private async Task<string?> CreateChallenge(Guid memberId, string purpose)
    {
        var now = DateTime.UtcNow;
        var challenges = context.EmailChallenges.Where(x => x.MemberId == memberId && x.Purpose == purpose);
        if (await challenges.AnyAsync(x => x.CreatedAt > now.AddMinutes(-1))) return null;
        await challenges.Where(x => x.ConsumedAt == null && x.ExpiresAt > now)
            .ExecuteUpdateAsync(s => s.SetProperty(x => x.ConsumedAt, now));
        var otp = RandomNumberGenerator.GetInt32(1_000_000).ToString("D6", System.Globalization.CultureInfo.InvariantCulture);
        var challenge = new EmailChallenge { MemberId = memberId, Purpose = purpose, CreatedAt = now, ExpiresAt = now.AddMinutes(15) };
        challenge.CodeHash = HashOtp(challenge.Id, otp);
        context.EmailChallenges.Add(challenge);
        await context.SaveChangesAsync();
        return otp;
    }

    private async Task<bool> ConsumeChallenge(Guid memberId, string purpose, string otp)
    {
        var now = DateTime.UtcNow;
        var challenge = await context.EmailChallenges
            .Where(x => x.MemberId == memberId && x.Purpose == purpose && x.ConsumedAt == null && x.ExpiresAt > now)
            .OrderByDescending(x => x.CreatedAt).FirstOrDefaultAsync();
        if (challenge is null || challenge.FailedAttempts >= 5) return false;
        var valid = CryptographicOperations.FixedTimeEquals(challenge.CodeHash, HashOtp(challenge.Id, otp));
        if (valid) challenge.ConsumedAt = now;
        else challenge.FailedAttempts++;
        await context.SaveChangesAsync();
        return valid;
    }

    private byte[] HashOtp(Guid id, string otp) => HMACSHA256.HashData(
        Encoding.UTF8.GetBytes(configuration["Jwt:SecretKey"]!), Encoding.UTF8.GetBytes($"email-otp:{id:N}:{otp}"));

    private static BusinessException InvalidOtp() => new(400, "INVALID_OTP", "Mã xác nhận không đúng hoặc đã hết hạn.");

    private static async Task SendOtp(IEmailService service, string email, string subject, string otp)
    {
        if (!await service.SendOtpAsync(email, subject, otp))
            throw new BusinessException(503, "EMAIL_UNAVAILABLE", "Không thể gửi email lúc này. Vui lòng thử lại sau.");
    }
}
