using Microsoft.EntityFrameworkCore;
namespace WebApi.Models;
// Stage2 only exposes seed categories. CRUD is implemented in stage3.
public class CategoryRepository(SportsBookingContext context) : BaseRepository(context)
{
    public Task<List<Category>> GetCategories()=>context.Categories.AsNoTracking().Where(x=>x.IsActive).OrderBy(x=>x.DisplayOrder).ThenBy(x=>x.Id).ToListAsync();
}
