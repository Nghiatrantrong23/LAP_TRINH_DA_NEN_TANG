using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using WebApi.Models;
namespace WebApi.Api.Controller;
[ApiController, Authorize(Roles = "Admin"), Route("api/admin/venue")]
public class VenueController : BaseController
{
    [HttpGet]
    public Task<List<Venue>> GetVenues()
    {
        return Provider.Product.GetVenues();
    }
}
