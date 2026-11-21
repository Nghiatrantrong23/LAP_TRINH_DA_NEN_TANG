using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using WebApi.Models;
namespace WebApi.Api.Controller;
[ApiController, Authorize, Route("api/member")]
public class MemberController : BaseController
{
    [HttpGet("me")]
    public Task<MemberDto> Me()
    {
        return Provider.Member.GetMember(MemberId);
    }
    [HttpPut("me")]
    public Task<MemberDto> Update(UpdateProfileModel model)
    {
        return Provider.Member.UpdateProfile(MemberId, model);
    }
}
