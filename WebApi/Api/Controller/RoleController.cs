using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using WebApi.Models;
namespace WebApi.Api.Controller;
[ApiController,Authorize(Roles="Admin"),Route("api/admin/role")]
public class RoleController : BaseController
{
    [HttpGet]
    public Task<List<Role>> GetRoles()=>Provider.Member.GetRoles();
}
