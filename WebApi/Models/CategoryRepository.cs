using Microsoft.EntityFrameworkCore;
namespace WebApi.Models;
// Stage2 only exposes seed categories. CRUD is implemented in stage3.
public class CategoryRepository : BaseRepository
{
    public CategoryRepository(SportsBookingContext context) : base(context)
    {
    }


    public Task<List<Category>> GetCategories()
    {
        return context.Categories.AsNoTracking().Where(x => x.IsActive).OrderBy(x => x.DisplayOrder).ThenBy(x => x.Id).ToListAsync();
    }
}
