using Microsoft.EntityFrameworkCore;
using WebApi.Services;
namespace WebApi.Models;
public class ProductRepository : BaseRepository
{
    private readonly FileStorage images;
    public ProductRepository(SportsBookingContext context, FileStorage images) : base(context) { this.images = images; }
    private IQueryable<Product> Query(bool admin)
    {
        return from p in context.Products.AsNoTracking()
               join c in context.Categories on p.CategoryId equals c.Id
               join v in context.Venues on p.VenueId equals v.Id
               where admin || (p.IsActive && c.IsActive && v.IsActive)
               select p;
    }
    private ProductDto ToDto(Product p, string category, string venue)
    {
        return new ProductDto { Id = p.Id, CategoryId = p.CategoryId, CategoryName = category, VenueId = p.VenueId, VenueName = venue, Type = p.Type, Name = p.Name, Description = p.Description, ImagePath = p.ImagePath, BasePrice = p.BasePrice, Unit = p.Unit, IsActive = p.IsActive, RowVersion = Convert.ToBase64String(p.RowVersion) };
    }
    public async Task<PageResult<ProductDto>> GetProducts(int? categoryId, string? search, int pageIndex, int pageSize, bool admin)
    {
        CatalogHelper.ValidatePage(pageIndex, pageSize);
        var query = Query(admin);
        if (categoryId != null)
        {
            query = query.Where(x => x.CategoryId == categoryId);
        }

        if (!string.IsNullOrWhiteSpace(search))
        {
            query = query.Where(x => x.Name.Contains(search.Trim()));
        }

        int total = await query.CountAsync();
        var products = await query.OrderByDescending(x => x.CreatedAt).ThenByDescending(x => x.Id).Skip((pageIndex - 1) * pageSize).Take(pageSize).ToListAsync();
        var categories = await context.Categories.ToDictionaryAsync(x => x.Id, x => x.Name);
        var venues = await context.Venues.ToDictionaryAsync(x => x.Id, x => x.Name);
        return new PageResult<ProductDto> { Items = products.Select(x => ToDto(x, categories[x.CategoryId], venues[x.VenueId])).ToList(), PageIndex = pageIndex, PageSize = pageSize, TotalItems = total, TotalPages = (int)Math.Ceiling(total / (double)pageSize) };
    }
    public async Task<ProductDto> GetProduct(int id, bool admin)
    {
        var p = await Query(admin).SingleOrDefaultAsync(x => x.Id == id) ?? throw new BusinessException(404, "NOT_FOUND", "Không tìm thấy sân hoặc dịch vụ.");
        var category = await context.Categories.Where(x => x.Id == p.CategoryId).Select(x => x.Name).SingleAsync();
        var venue = await context.Venues.Where(x => x.Id == p.VenueId).Select(x => x.Name).SingleAsync();
        var dto = ToDto(p, category, venue);
        if (p.Type == "Court")
        {
            var profile = await context.CourtProfiles.AsNoTracking().SingleAsync(x => x.ProductId == id);
            var schedule = await context.CourtSchedules.AsNoTracking().Where(x => x.CourtId == id).OrderBy(x => x.DayOfWeek).FirstOrDefaultAsync();
            var rule = await context.CourtPriceRules.AsNoTracking().Where(x => x.CourtId == id && x.IsActive && (x.EffectiveTo == null || x.EffectiveTo >= DateOnly.FromDateTime(DateTime.UtcNow))).OrderByDescending(x => x.EffectiveFrom).ThenBy(x => x.DayOfWeek).FirstOrDefaultAsync();
            dto.Capacity = profile.Capacity;
            dto.Indoor = profile.Indoor;
            dto.Surface = profile.Surface;
            dto.OpenTime = schedule?.OpenTime;
            dto.CloseTime = schedule?.CloseTime;
            dto.PeakStartTime = rule?.StartTime;
            dto.PeakEndTime = rule?.EndTime;
            dto.PeakPrice = rule?.PricePerHour;
        }
        return dto;
    }
    public Task<List<Venue>> GetVenues() { return context.Venues.AsNoTracking().OrderBy(x => x.Id).ToListAsync(); }
    private async Task Validate(ProductModel m, Product? previous = null)
    {
        if (string.IsNullOrWhiteSpace(m.Name) || string.IsNullOrWhiteSpace(m.Unit) || m.Type is not ("Court" or "Service"))
        {
            throw new BusinessException(400, "INVALID_PRODUCT", "Kiểm tra tên, đơn vị và loại sản phẩm.");
        }

        if (!await context.Categories.AnyAsync(x => x.Id == m.CategoryId && (!m.IsActive || x.IsActive)) || !await context.Venues.AnyAsync(x => x.Id == m.VenueId && (!m.IsActive || x.IsActive)))
        {
            throw new BusinessException(400, "INVALID_CATEGORY_OR_VENUE", "Chọn danh mục và cơ sở hợp lệ; sản phẩm hoạt động cần danh mục/cơ sở hoạt động.");
        }

        if (previous != null && previous.Type != m.Type)
        {
            throw new BusinessException(409, "IMMUTABLE_TYPE", "Không đổi loại sân thành dịch vụ hoặc ngược lại. Hãy tạo sản phẩm mới.");
        }

        if (m.Type == "Court")
        {
            bool aligned(TimeOnly? t)
            { return t != null && t.Value.Ticks % (TimeSpan.TicksPerMinute * 30) == 0; }
            if (m.Capacity is null or < 2 or > 100 || m.PeakPrice == null || !aligned(m.OpenTime) || !aligned(m.CloseTime) || !aligned(m.PeakStartTime) || !aligned(m.PeakEndTime)
                || m.OpenTime >= m.CloseTime || m.PeakStartTime >= m.PeakEndTime || m.PeakStartTime < m.OpenTime || m.PeakEndTime > m.CloseTime)
            {
                throw new BusinessException(400, "INVALID_COURT", "Sân cần sức chứa 2–100, giờ hoạt động và giờ vàng theo bước 30 phút; giờ vàng nằm trong giờ mở cửa.");
            }
        }
    }
    private async Task ProtectBookings(Product p, ProductModel m)
    {
        if (p.Type != "Court")
        {
            return;
        }

        var profile = await context.CourtProfiles.AsNoTracking().SingleAsync(x => x.ProductId == p.Id);
        var schedule = await context.CourtSchedules.AsNoTracking().Where(x => x.CourtId == p.Id).OrderBy(x => x.DayOfWeek).FirstOrDefaultAsync();
        bool changed = !m.IsActive || p.CategoryId != m.CategoryId || p.VenueId != m.VenueId || profile.Capacity != m.Capacity || (schedule != null && (schedule.OpenTime != m.OpenTime || schedule.CloseTime != m.CloseTime));
        if (changed && await (from line in context.OrderItems join order in context.Orders on line.OrderId equals order.Id where line.ProductId == p.Id && (order.Status == "PendingDeposit" || order.Status == "Confirmed" || order.Status == "Playing") select line.Id).AnyAsync())
        {
            throw new BusinessException(409, "ACTIVE_BOOKINGS", "Sân còn đơn chưa kết thúc, chưa thể ngừng hoạt động hoặc đổi cơ sở, sức chứa, giờ mở cửa.");
        }
    }
    private void Apply(Product p, ProductModel m, string? image)
    {
        p.CategoryId = m.CategoryId;
        p.VenueId = m.VenueId;
        p.Name = m.Name.Trim();
        p.Description = m.Description?.Trim();
        p.Type = m.Type;
        p.BasePrice = m.BasePrice;
        p.Unit = m.Unit.Trim();
        p.IsActive = m.IsActive;
        p.UpdatedAt = DateTime.UtcNow;
        if (image != null)
        {
            p.ImagePath = image;
        }
    }
    private async Task SaveCourt(Product p, ProductModel m, bool create)
    {
        if (p.Type != "Court")
        {
            return;
        }

        var profile = create ? new CourtProfile { ProductId = p.Id } : await context.CourtProfiles.SingleAsync(x => x.ProductId == p.Id);
        profile.Capacity = m.Capacity!.Value;
        profile.Indoor = m.Indoor;
        profile.Surface = m.Surface?.Trim();
        if (create)
        {
            context.CourtProfiles.Add(profile);
        }

        await context.SaveChangesAsync();
        await context.CourtSchedules.Where(x => x.CourtId == p.Id).ExecuteDeleteAsync();
        await context.CourtPriceRules.Where(x => x.CourtId == p.Id).ExecuteDeleteAsync();
        for (byte day = 0; day < 7; day++)
        {
            context.CourtSchedules.Add(new CourtSchedule { CourtId = p.Id, DayOfWeek = day, OpenTime = m.OpenTime!.Value, CloseTime = m.CloseTime!.Value });
            context.CourtPriceRules.Add(new CourtPriceRule { CourtId = p.Id, DayOfWeek = day, StartTime = m.PeakStartTime!.Value, EndTime = m.PeakEndTime!.Value, PricePerHour = m.PeakPrice!.Value, EffectiveFrom = DateOnly.FromDateTime(DateTime.UtcNow) });
        }
        await context.SaveChangesAsync();
    }
    public async Task<ProductDto> Add(ProductModel m)
    {
        await Validate(m);
        if (m.Image == null)
        {
            throw new BusinessException(400, "IMAGE_REQUIRED", "Sản phẩm mới bắt buộc có ảnh.");
        }

        string? image = await images.Stage(m.Image, "products");
        try
        {
            await using var tx = await context.Database.BeginTransactionAsync();
            var p = new Product();
            Apply(p, m, image);
            context.Products.Add(p);
            await context.SaveChangesAsync();
            await SaveCourt(p, m, true);
            await context.FileDeletionJobs.Where(x => x.RelativePath == image && x.CompletedAt == null).ExecuteDeleteAsync();
            await tx.CommitAsync();
            return await GetProduct(p.Id, true);
        }
        catch { await images.Discard(image); throw; }
    }
    public async Task<ProductDto> Update(int id, ProductModel m)
    {
        var previous = await context.Products.AsNoTracking().SingleOrDefaultAsync(x => x.Id == id) ?? throw new BusinessException(404, "NOT_FOUND", "Không tìm thấy sản phẩm.");
        CatalogHelper.RequireVersion(previous.RowVersion, m.RowVersion);
        await Validate(m, previous);
        string? image = await images.Stage(m.Image, "products");
        try
        {
            await using var tx = await context.Database.BeginTransactionAsync();
            var p = await context.Products.FromSqlInterpolated($"SELECT * FROM Products WITH (UPDLOCK,HOLDLOCK) WHERE Id={id}").SingleOrDefaultAsync() ?? throw new BusinessException(404, "NOT_FOUND", "Không tìm thấy sản phẩm.");
            CatalogHelper.RequireVersion(p.RowVersion, m.RowVersion);
            await ProtectBookings(p, m);
            if (image != null && p.ImagePath != null)
            {
                context.FileDeletionJobs.Add(new FileDeletionJob { RelativePath = p.ImagePath });
            }

            Apply(p, m, image);
            await context.SaveChangesAsync();
            await SaveCourt(p, m, false);
            if (image != null)
            {
                await context.FileDeletionJobs.Where(x => x.RelativePath == image && x.CompletedAt == null).ExecuteDeleteAsync();
            }

            await tx.CommitAsync();
            return await GetProduct(id, true);
        }
        catch { await images.Discard(image); throw; }
    }
    public async Task Delete(int id, string version)
    {
        await using var tx = await context.Database.BeginTransactionAsync();
        var p = await context.Products.FromSqlInterpolated($"SELECT * FROM Products WITH (UPDLOCK,HOLDLOCK) WHERE Id={id}").SingleOrDefaultAsync() ?? throw new BusinessException(404, "NOT_FOUND", "Không tìm thấy sản phẩm.");
        CatalogHelper.RequireVersion(p.RowVersion, version);
        if (await context.OrderItems.AnyAsync(x => x.ProductId == id) || await context.CartItems.AnyAsync(x => x.ProductId == id))
        {
            throw new BusinessException(409, "PRODUCT_IN_USE", "Sản phẩm có trong giỏ hoặc đơn hàng. Không thể xóa cứng.");
        }

        if (p.Type == "Court")
        {
            var slots = context.CourtSlots.Where(x => x.CourtId == id).Select(x => x.Id);
            if (await context.OrderItemSlots.AnyAsync(x => slots.Contains(x.CourtSlotId)) || await context.SlotReservations.AnyAsync(x => slots.Contains(x.CourtSlotId)))
            {
                throw new BusinessException(409, "COURT_IN_USE", "Lịch sân đã được sử dụng; không thể xóa.");
            }

            await context.CourtSlots.Where(x => x.CourtId == id).ExecuteDeleteAsync();
            await context.CourtPriceRules.Where(x => x.CourtId == id).ExecuteDeleteAsync();
            await context.CourtSchedules.Where(x => x.CourtId == id).ExecuteDeleteAsync();
            await context.CourtProfiles.Where(x => x.ProductId == id).ExecuteDeleteAsync();
        }
        if (p.ImagePath != null)
        {
            context.FileDeletionJobs.Add(new FileDeletionJob { RelativePath = p.ImagePath });
        }

        context.Products.Remove(p);
        await context.SaveChangesAsync();
        await tx.CommitAsync();
    }
}
