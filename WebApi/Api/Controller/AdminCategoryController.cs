using System.ComponentModel.DataAnnotations;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using WebApi.Models;
namespace WebApi.Api.Controller;
[ApiController, Authorize(Roles = "Admin"), Route("api/admin/category"), RequestSizeLimit(6 * 1024 * 1024)]
public class AdminCategoryController : BaseController
{
    [HttpGet]
    public Task<PageResult<Category>> GetCategories(string? search, int pageIndex = 1, int pageSize = 10)
    {
        return Provider.Category.GetCategories(search, pageIndex, pageSize);
    }
    [HttpGet("{id:int}")]
    public Task<Category> GetCategory(int id)
    {
        return Provider.Category.GetCategory(id);
    }
    [HttpPost]
    public async Task<IActionResult> Add([FromForm] CategoryModel model)
    {
        var category = await Provider.Category.Add(model);
        return CreatedAtAction(nameof(GetCategory), new { id = category.Id }, category);
    }
    [HttpPut("{id:int}")]
    public Task<Category> Update(int id, [FromForm] CategoryModel model)
    {
        return Provider.Category.Update(id, model);
    }
    [HttpDelete("{id:int}")]
    public async Task<IActionResult> Delete(int id, [FromQuery, Required] string rowVersion)
    {
        await Provider.Category.Delete(id, rowVersion);
        return NoContent();
    }
}
