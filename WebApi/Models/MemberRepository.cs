using System.Data;
using Microsoft.EntityFrameworkCore;
using WebApi.Services;
namespace WebApi.Models;
public class MemberRepository : BaseRepository
{
    public MemberRepository(SportsBookingContext context) : base(context)
    {
    }


    public async Task<MemberDto> GetMember(Guid id)
    {
        var member = await context.Members.AsNoTracking().Include(x => x.Role).SingleOrDefaultAsync(x => x.Id == id) ?? throw new BusinessException(404, "NOT_FOUND", "Không tìm thấy thành viên.");
        return Helper.ToDto(member);
    }
    public async Task<PageResult<MemberDto>> GetMembers(string? search, int pageIndex, int pageSize)
    {
        if (pageIndex < 1 || pageIndex > 1000000 || pageSize < 1 || pageSize > 100)
        {
            throw new BusinessException(400, "INVALID_PAGE", "pageIndex từ 1 đến 1000000, pageSize từ 1 đến 100.");
        }

        var query = context.Members.AsNoTracking().Include(x => x.Role).AsQueryable();
        if (!string.IsNullOrWhiteSpace(search))
        {
            var text = search.Trim();
            query = query.Where(x => x.Email.Contains(text) || x.GivenName.Contains(text) || x.Surname.Contains(text));
        }
        var total = await query.CountAsync();
        var members = await query.OrderBy(x => x.NormalizedEmail).ThenBy(x => x.Id).Skip((pageIndex - 1) * pageSize).Take(pageSize).ToListAsync();
        return new PageResult<MemberDto>
        {
            Items = members.Select(Helper.ToDto).ToList(),
            PageIndex = pageIndex,
            PageSize = pageSize,
            TotalItems = total,
            TotalPages = (int)Math.Ceiling(total / (double)pageSize)
        };
    }
    public async Task<MemberDto> UpdateProfile(Guid id, UpdateProfileModel model)
    {
        if (string.IsNullOrWhiteSpace(model.GivenName))
        {
            throw new BusinessException(400, "NAME_REQUIRED", "Nhập tên của bạn.");
        }

        var member = await context.Members.Include(x => x.Role).SingleOrDefaultAsync(x => x.Id == id) ?? throw new BusinessException(404, "NOT_FOUND", "Không tìm thấy thành viên.");
        Helper.RequireVersion(member, model.RowVersion);
        member.GivenName = model.GivenName.Trim();
        member.Surname = (model.Surname ?? "").Trim();
        member.Phone = model.Phone?.Trim();
        member.UpdatedAt = DateTime.UtcNow;
        await context.SaveChangesAsync();
        return Helper.ToDto(member);
    }
    public async Task<MemberDto> ChangeAccess(Guid actorId, Guid id, string version, short? roleId, bool? locked)
    {
        if (roleId != null && !await context.Roles.AnyAsync(x => x.Id == roleId))
        {
            throw new BusinessException(400, "INVALID_ROLE", "Quyền không tồn tại.");
        }

        await using var tx = await context.Database.BeginTransactionAsync(IsolationLevel.Serializable);
        var admins = await context.Members.FromSqlRaw("SELECT * FROM Members WITH (UPDLOCK,HOLDLOCK) WHERE RoleId=2").ToListAsync();
        var member = await context.Members.FromSqlInterpolated($"SELECT * FROM Members WITH (UPDLOCK,HOLDLOCK) WHERE Id={id}").SingleOrDefaultAsync() ?? throw new BusinessException(404, "NOT_FOUND", "Không tìm thấy thành viên.");
        Helper.RequireVersion(member, version);
        var nextRole = roleId ?? member.RoleId;
        var nextLocked = locked ?? member.IsLocked;
        if (actorId == id && (nextRole != 2 || nextLocked))
        {
            throw new BusinessException(409, "SELF_ACCESS_CHANGE", "Không được tự khóa hoặc hạ quyền tài khoản đang sử dụng.");
        }

        if (member.RoleId == 2 && !member.IsLocked && (nextRole != 2 || nextLocked) && admins.Count(x => !x.IsLocked) <= 1)
        {
            throw new BusinessException(409, "LAST_ADMIN", "Cần ít nhất một Admin đang hoạt động.");
        }

        if (member.RoleId != nextRole || member.IsLocked != nextLocked)
        {
            member.RoleId = nextRole;
            member.IsLocked = nextLocked;
            member.SecurityVersion++;
            member.UpdatedAt = DateTime.UtcNow;
            await context.AuthSessions.Where(x => x.MemberId == id && x.RevokedAt == null).ExecuteUpdateAsync(s => s.SetProperty(x => x.RevokedAt, DateTime.UtcNow));
            await context.SaveChangesAsync();
        }
        member.Role = await context.Roles.SingleAsync(x => x.Id == member.RoleId);
        await tx.CommitAsync();
        return Helper.ToDto(member);
    }
    public Task<List<Role>> GetRoles()
    {
        return context.Roles.AsNoTracking().OrderBy(x => x.Id).ToListAsync();
    }
}
