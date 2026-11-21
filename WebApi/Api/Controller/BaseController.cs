using System.Security.Claims;
using Microsoft.AspNetCore.Mvc;
using WebApi.Models;
namespace WebApi.Api.Controller;
public abstract class BaseController : ControllerBase
{
    private SiteProvider? provider;
    protected SiteProvider Provider => provider ??= HttpContext.RequestServices.GetRequiredService<SiteProvider>();
    protected Guid MemberId => Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
    protected Guid SessionId => Guid.Parse(User.FindFirstValue("sid")!);
}
