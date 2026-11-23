using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using WebApi.Models;
namespace WebApi.Api.Controller;

[Authorize, ApiController, Route("api/cart")]
public class CartController : BaseController
{
    [HttpGet]
    public Task<List<CartDto>> GetCart()
    {
        return Provider.Cart.GetCartAsync(MemberId);
    }

    [HttpGet("count")]
    public Task<int> GetCount()
    {
        return Provider.Cart.CountAsync(MemberId);
    }

    [HttpPost]
    public async Task<IActionResult> AddToCart([FromBody] CartAddModel model)
    {
        int ret = await Provider.Cart.AddToCartAsync(MemberId, model.ProductId, model.Quantity);
        if (ret == -4) return NotFound(new { message = "Sản phẩm không tồn tại hoặc ngừng hoạt động." });
        return Ok(ret);
    }

    [HttpPut("{id:long}")]
    public async Task<IActionResult> UpdateQuantity(long id, [FromBody] CartUpdateModel model)
    {
        int ret = await Provider.Cart.UpdateQuantityAsync(MemberId, id, model.Quantity);
        if (ret == -1) return NotFound(new { message = "Không tìm thấy mục trong giỏ." });
        return Ok(ret);
    }

    [HttpDelete("{id:long}")]
    public async Task<IActionResult> Delete(long id)
    {
        int ret = await Provider.Cart.DeleteItemAsync(MemberId, id);
        if (ret == -1) return NotFound(new { message = "Không tìm thấy mục trong giỏ." });
        return Ok(ret);
    }
}

public class CartAddModel
{
    public int ProductId { get; set; }
    public int Quantity { get; set; } = 1;
}

public class CartUpdateModel
{
    public int Quantity { get; set; }
}
