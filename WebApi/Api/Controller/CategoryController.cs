using Microsoft.AspNetCore.Mvc;
using WebApi.Models;
namespace WebApi.Api.Controller;
[ApiController,Route("api/category")]
public class CategoryController : BaseController
{
    [HttpGet]
    public Task<List<Category>> GetCategories()=>Provider.Category.GetCategories();
}
