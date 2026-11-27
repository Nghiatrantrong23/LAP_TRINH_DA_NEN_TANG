using Microsoft.EntityFrameworkCore;
using WebApi.Services;
namespace WebApi.Models;
public class CategoryRepository : BaseRepository
{
    private readonly FileStorage images;
    public CategoryRepository(SportsBookingContext context, FileStorage images) : base(context) { this.images = images; }
    public Task<List<Category>> GetCategories()
    {
        return context.Categories.AsNoTracking().Where(x => x.IsActive).OrderBy(x => x.DisplayOrder).ThenBy(x => x.Id).ToListAsync();
    }
    public async Task<PageResult<Category>> GetCategories(string? search, int pageIndex, int pageSize)
    {
        CatalogHelper.ValidatePage(pageIndex, pageSize);
        var query = context.Categories.AsNoTracking().AsQueryable();
        if (!string.IsNullOrWhiteSpace(search))
        {
            query = query.Where(x => x.Name.Contains(search.Trim()));
        }

        int total = await query.CountAsync();
        return new PageResult<Category> { Items = await query.OrderBy(x => x.DisplayOrder).ThenBy(x => x.Id).Skip((pageIndex - 1) * pageSize).Take(pageSize).ToListAsync(), PageIndex = pageIndex, PageSize = pageSize, TotalItems = total, TotalPages = (int)Math.Ceiling(total / (double)pageSize) };
    }
    public async Task<Category> GetCategory(int id)
    {
        return await context.Categories.AsNoTracking().SingleOrDefaultAsync(x => x.Id == id) ?? throw new BusinessException(404, "NOT_FOUND", "Không tìm thấy danh mục.");
    }
    private async Task Validate(CategoryModel model, int? id)
    {
        if (string.IsNullOrWhiteSpace(model.Name))
        {
            throw new BusinessException(400, "NAME_REQUIRED", "Nhập tên danh mục.");
        }

        if (await context.Categories.AnyAsync(x => x.Name == model.Name.Trim() && x.Id != id))
        {
            throw new BusinessException(409, "CATEGORY_EXISTS", "Tên danh mục đã tồn tại.");
        }
    }
    public async Task<Category> Add(CategoryModel model)
    {
        await Validate(model, null);
        string? image = await images.Stage(model.Image, "categories");
        try
        {
            await using var tx = await context.Database.BeginTransactionAsync();
            var category = new Category { Name = model.Name.Trim(), Description = model.Description?.Trim(), DisplayOrder = model.DisplayOrder, IsActive = model.IsActive, ImagePath = image };
            context.Categories.Add(category);
            await context.SaveChangesAsync();
            if (image != null)
            {
                await context.FileDeletionJobs.Where(x => x.RelativePath == image && x.CompletedAt == null).ExecuteDeleteAsync();
            }

            await tx.CommitAsync();
            return category;
        }
        catch { await images.Discard(image); throw; }
    }
    public async Task<Category> Update(int id, CategoryModel model)
    {
        var current = await GetCategory(id);
        CatalogHelper.RequireVersion(current.RowVersion, model.RowVersion);
        await Validate(model, id);
        string? image = await images.Stage(model.Image, "categories");
        try
        {
            await using var tx = await context.Database.BeginTransactionAsync();
            var category = await context.Categories.FromSqlInterpolated($"SELECT * FROM Categories WITH (UPDLOCK,HOLDLOCK) WHERE Id={id}").SingleOrDefaultAsync() ?? throw new BusinessException(404, "NOT_FOUND", "Không tìm thấy danh mục.");
            CatalogHelper.RequireVersion(category.RowVersion, model.RowVersion);
            category.Name = model.Name.Trim();
            category.Description = model.Description?.Trim();
            category.DisplayOrder = model.DisplayOrder;
            category.IsActive = model.IsActive;
            if (image != null)
            { if (category.ImagePath != null) { context.FileDeletionJobs.Add(new FileDeletionJob { RelativePath = category.ImagePath }); } category.ImagePath = image; }
            context.Entry(category).Property(x => x.Name).IsModified = true;
            await context.SaveChangesAsync();
            if (image != null)
            {
                await context.FileDeletionJobs.Where(x => x.RelativePath == image && x.CompletedAt == null).ExecuteDeleteAsync();
            }

            await tx.CommitAsync();
            return category;
        }
        catch { await images.Discard(image); throw; }
    }
    public async Task Delete(int id, string rowVersion)
    {
        await using var tx = await context.Database.BeginTransactionAsync();
        var category = await context.Categories.FromSqlInterpolated($"SELECT * FROM Categories WITH (UPDLOCK,HOLDLOCK) WHERE Id={id}").SingleOrDefaultAsync() ?? throw new BusinessException(404, "NOT_FOUND", "Không tìm thấy danh mục.");
        CatalogHelper.RequireVersion(category.RowVersion, rowVersion);
        if (await context.Products.AnyAsync(x => x.CategoryId == id))
        {
            throw new BusinessException(409, "CATEGORY_HAS_PRODUCTS", "Danh mục còn sân hoặc dịch vụ; không thể xóa.");
        }

        if (category.ImagePath != null)
        {
            context.FileDeletionJobs.Add(new FileDeletionJob { RelativePath = category.ImagePath });
        }

        context.Categories.Remove(category);
        await context.SaveChangesAsync();
        await tx.CommitAsync();
    }
}
