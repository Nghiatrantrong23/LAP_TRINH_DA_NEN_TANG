using Microsoft.AspNetCore.Mvc;
using WebApi.Models;
namespace WebApi.Api.Controller;
[ApiController, Route("api/product")]
public class ProductController : BaseController
{
    [HttpGet]
    public Task<PageResult<ProductDto>> GetProducts(int? categoryId, string? search, int pageIndex = 1, int pageSize = 10)
    {
        return Provider.Product.GetProducts(categoryId, search, pageIndex, pageSize, false);
    }
    [HttpGet("{id:int}")]
    public Task<ProductDto> GetProduct(int id)
    {
        return Provider.Product.GetProduct(id, false);
    }
}
