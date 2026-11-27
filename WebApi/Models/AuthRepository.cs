using System.Data;
using Microsoft.EntityFrameworkCore;
using WebApi.Services;
namespace WebApi.Models;
public partial class AuthRepository : BaseRepository
{
    private readonly IConfiguration configuration;

    public AuthRepository(SportsBookingContext context, IConfiguration configuration) : base(context)
    {
        this.configuration = configuration;
    }


    public async Task<MemberDto> Register(RegisterModel model)
    {
        Helper.ValidatePassword(model.Password);
        if (string.IsNullOrWhiteSpace(model.GivenName))
        {
            throw new BusinessException(400, "NAME_REQUIRED", "Nhập tên của bạn.");
        }

        var normalized = Helper.NormalizeEmail(model.Email);
        if (normalized.EndsWith("@SPORTBOOKING.INVALID", StringComparison.Ordinal))
        {
            throw new BusinessException(400, "RESERVED_EMAIL", "Email này dành riêng cho tài khoản demo.");
        }
        if (await context.Members.AnyAsync(x => x.NormalizedEmail == normalized))
        {
            throw new BusinessException(409, "EMAIL_EXISTS", "Email đã được đăng ký.");
        }

        var member = new Member { Email = model.Email.Trim(), NormalizedEmail = normalized, GivenName = model.GivenName.Trim(), Surname = (model.Surname ?? "").Trim(), Phone = model.Phone?.Trim(), RoleId = 1, PasswordHash = BCrypt.Net.BCrypt.HashPassword(model.Password) };
        member.Role = await context.Roles.SingleAsync(x => x.Id == 1);
        context.Members.Add(member);
        context.Carts.Add(new Cart { MemberId = member.Id });
        await context.SaveChangesAsync();
        return Helper.ToDto(member);
    }
    public async Task<LoginResponse> Login(LoginModel model)
    {
        if (System.Text.Encoding.UTF8.GetByteCount(model.Password) > 72)
        {
            throw new BusinessException(401, "INVALID_CREDENTIALS", "Email hoặc mật khẩu không đúng.");
        }

        var normalized = Helper.NormalizeEmail(model.Email);
        var member = await context.Members.Include(x => x.Role).SingleOrDefaultAsync(x => x.NormalizedEmail == normalized);
        if (member == null || !BCrypt.Net.BCrypt.Verify(model.Password, member.PasswordHash))
        {
            throw new BusinessException(401, "INVALID_CREDENTIALS", "Email hoặc mật khẩu không đúng.");
        }

        if (member.IsLocked)
        {
            throw new BusinessException(403, "ACCOUNT_LOCKED", "Tài khoản đã bị khóa.");
        }

        return await CreateSession(member);
    }

    private async Task<LoginResponse> CreateSession(Member member)
    {
        var refresh = Helper.NewRefreshToken();
        var session = new AuthSession { MemberId = member.Id, RefreshTokenHash = Helper.HashToken(refresh), ExpiresAt = DateTime.UtcNow.AddDays(configuration.GetValue<int>("Jwt:RefreshDays", 30)) };
        context.AuthSessions.Add(session);
        await context.SaveChangesAsync();
        return Helper.Tokens(member, session, refresh, configuration);
    }
    public async Task<LoginResponse> Refresh(string refreshToken)
    {
        var hash = Helper.HashToken(refreshToken);
        var previous = await context.AuthSessions.AsNoTracking().SingleOrDefaultAsync(x => x.RefreshTokenHash == hash);
        if (previous == null)
        {
            throw new BusinessException(401, "INVALID_REFRESH_TOKEN", "Phiên đăng nhập không còn hiệu lực.");
        }

        await using var tx = await context.Database.BeginTransactionAsync(IsolationLevel.ReadCommitted);
        var member = await context.Members.FromSqlInterpolated($"SELECT * FROM Members WITH (UPDLOCK,HOLDLOCK) WHERE Id={previous.MemberId}").SingleAsync();
        var session = await context.AuthSessions.FromSqlInterpolated($"SELECT * FROM AuthSessions WITH (UPDLOCK,HOLDLOCK) WHERE Id={previous.Id}").SingleAsync();
        if (!session.RefreshTokenHash.SequenceEqual(hash) || session.RevokedAt != null || session.ExpiresAt <= DateTime.UtcNow || member.IsLocked)
        {
            throw new BusinessException(401, "INVALID_REFRESH_TOKEN", "Phiên đăng nhập không còn hiệu lực.");
        }

        member.Role = await context.Roles.SingleAsync(x => x.Id == member.RoleId);
        var refresh = Helper.NewRefreshToken();
        session.RefreshTokenHash = Helper.HashToken(refresh);
        await context.SaveChangesAsync();
        await tx.CommitAsync();
        return Helper.Tokens(member, session, refresh, configuration);
    }
    public async Task Logout(Guid memberId, Guid sessionId)
    {
        await context.AuthSessions.Where(x => x.MemberId == memberId && x.Id == sessionId && x.RevokedAt == null).ExecuteUpdateAsync(s => s.SetProperty(x => x.RevokedAt, DateTime.UtcNow));
    }
    public async Task ChangePassword(Guid memberId, ChangePasswordModel model)
    {
        Helper.ValidatePassword(model.NewPassword);
        await using var tx = await context.Database.BeginTransactionAsync(IsolationLevel.ReadCommitted);
        var member = await context.Members.FromSqlInterpolated($"SELECT * FROM Members WITH (UPDLOCK,HOLDLOCK) WHERE Id={memberId}").SingleAsync();
        if (System.Text.Encoding.UTF8.GetByteCount(model.CurrentPassword) > 72 || !BCrypt.Net.BCrypt.Verify(model.CurrentPassword, member.PasswordHash))
        {
            throw new BusinessException(400, "WRONG_PASSWORD", "Mật khẩu hiện tại không đúng.");
        }

        member.PasswordHash = BCrypt.Net.BCrypt.HashPassword(model.NewPassword);
        member.SecurityVersion++;
        member.UpdatedAt = DateTime.UtcNow;
        await context.AuthSessions.Where(x => x.MemberId == memberId && x.RevokedAt == null).ExecuteUpdateAsync(s => s.SetProperty(x => x.RevokedAt, DateTime.UtcNow));
        await context.SaveChangesAsync();
        await tx.CommitAsync();
    }
}
