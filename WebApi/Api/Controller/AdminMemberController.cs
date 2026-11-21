using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using WebApi.Models;
namespace WebApi.Api.Controller;
[ApiController,Authorize(Roles="Admin"),Route("api/admin/member")]
public class AdminMemberController : BaseController
{
    [HttpGet]
    public Task<PageResult<MemberDto>> GetMembers(string? search,int pageIndex=1,int pageSize=10)=>Provider.Member.GetMembers(search,pageIndex,pageSize);
    [HttpGet("{id:guid}")]
    public Task<MemberDto> GetMember(Guid id)=>Provider.Member.GetMember(id);
    [HttpPut("{id:guid}")]
    public Task<MemberDto> Update(Guid id,UpdateProfileModel model)=>Provider.Member.UpdateProfile(id,model);
    [HttpPut("{id:guid}/role")]
    public Task<MemberDto> Role(Guid id,UpdateRoleModel model)=>Provider.Member.ChangeAccess(MemberId,id,model.RowVersion,model.RoleId,null);
    [HttpPut("{id:guid}/lock")]
    public Task<MemberDto> Lock(Guid id,LockMemberModel model)=>Provider.Member.ChangeAccess(MemberId,id,model.RowVersion,null,model.IsLocked);
}
