using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using WebApi.Models;

namespace WebApi.Api.Controller;

[Authorize, ApiController, Route("api/orders")]
public class OrderController : BaseController
{
    [HttpPost("checkout")]
    public async Task<IActionResult> Checkout([FromBody] CheckoutModel? model)
    {
        var order = await Provider.Order.CheckoutAsync(
            MemberId,
            model?.CustomerName,
            model?.CustomerPhone,
            model?.Note);
        return Ok(order);
    }
}

public class CheckoutModel
{
    public string? CustomerName { get; set; }
    public string? CustomerPhone { get; set; }
    public string? Note { get; set; }
}
