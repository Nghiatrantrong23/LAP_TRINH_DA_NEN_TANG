using System.ComponentModel.DataAnnotations;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using WebApi.Models;
namespace WebApi.Api.Controller;
[ApiController, Authorize(Roles = "Admin"), Route("api/admin/product"), RequestSizeLimit(6 * 1024 * 1024)]
public class AdminProductController : BaseController
{
    [HttpGet]
    public Task<PageResult<ProductDto>> GetProducts(int? categoryId, string? search, int pageIndex = 1, int pageSize = 10)
    {
        return Provider.Product.GetProducts(categoryId, search, pageIndex, pageSize, true);
    }
    [HttpGet("{id:int}")]
    public Task<ProductDto> GetProduct(int id)
    {
        return Provider.Product.GetProduct(id, true);
    }
    [HttpPost]
    public async Task<IActionResult> Add([FromForm] ProductModel model)
    {
        var product = await Provider.Product.Add(model);
        return CreatedAtAction(nameof(GetProduct), new { id = product.Id }, product);
    }
    [HttpPut("{id:int}")]
    public Task<ProductDto> Update(int id, [FromForm] ProductModel model)
    {
        return Provider.Product.Update(id, model);
    }
    [HttpDelete("{id:int}")]
    public async Task<IActionResult> Delete(int id, [FromQuery, Required] string rowVersion)
    {
        await Provider.Product.Delete(id, rowVersion);
        return NoContent();
    }
}
