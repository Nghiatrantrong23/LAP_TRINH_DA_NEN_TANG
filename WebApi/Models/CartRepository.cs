using Microsoft.EntityFrameworkCore;
namespace WebApi.Models;

public class CartDto
{
    public long Id { get; set; }
    public int ProductId { get; set; }
    public string Name { get; set; } = "";
    public string Type { get; set; } = "";
    public string Unit { get; set; } = "";
    public string? ImagePath { get; set; }
    public decimal BasePrice { get; set; }
    public int Quantity { get; set; }
    public decimal Amount => BasePrice * Quantity;
}

public class CartRepository : BaseRepository
{
    public CartRepository(SportsBookingContext context) : base(context) { }

    public async Task<List<CartDto>> GetCartAsync(Guid memberId)
    {
        var cart = await context.Carts.AsNoTracking().FirstOrDefaultAsync(x => x.MemberId == memberId);
        if (cart == null) return new List<CartDto>();

        return await (
            from ci in context.CartItems.AsNoTracking()
            join p in context.Products.AsNoTracking() on ci.ProductId equals p.Id
            where ci.CartId == cart.Id
            select new CartDto
            {
                Id = ci.Id,
                ProductId = p.Id,
                Name = p.Name,
                Type = p.Type,
                Unit = p.Unit,
                ImagePath = p.ImagePath,
                BasePrice = p.BasePrice,
                Quantity = ci.Quantity
            }
        ).ToListAsync();
    }

    public async Task<int> AddToCartAsync(Guid memberId, int productId, int quantity)
    {
        if (quantity < 1) return -3;
        if (!await context.Products.AnyAsync(x => x.Id == productId && x.IsActive)) return -4;

        var cart = await context.Carts.FirstOrDefaultAsync(x => x.MemberId == memberId);
        if (cart == null)
        {
            cart = new Cart { MemberId = memberId };
            context.Carts.Add(cart);
            await context.SaveChangesAsync();
        }

        var existing = await context.CartItems.FirstOrDefaultAsync(x => x.CartId == cart.Id && x.ProductId == productId);
        if (existing != null)
        {
            existing.Quantity += quantity;
        }
        else
        {
            context.CartItems.Add(new CartItem { CartId = cart.Id, ProductId = productId, Quantity = quantity });
        }

        cart.UpdatedAt = DateTime.UtcNow;
        return await context.SaveChangesAsync();
    }

    public async Task<int> UpdateQuantityAsync(Guid memberId, long itemId, int quantity)
    {
        if (quantity < 1) return -3;
        var cart = await context.Carts.FirstOrDefaultAsync(x => x.MemberId == memberId);
        if (cart == null) return -1;
        var item = await context.CartItems.FirstOrDefaultAsync(x => x.Id == itemId && x.CartId == cart.Id);
        if (item == null) return -1;
        item.Quantity = quantity;
        cart.UpdatedAt = DateTime.UtcNow;
        return await context.SaveChangesAsync();
    }

    public async Task<int> DeleteItemAsync(Guid memberId, long itemId)
    {
        var cart = await context.Carts.FirstOrDefaultAsync(x => x.MemberId == memberId);
        if (cart == null) return -1;
        var item = await context.CartItems.FirstOrDefaultAsync(x => x.Id == itemId && x.CartId == cart.Id);
        if (item == null) return -1;
        context.CartItems.Remove(item);
        cart.UpdatedAt = DateTime.UtcNow;
        return await context.SaveChangesAsync();
    }

    public async Task<int> CountAsync(Guid memberId)
    {
        var cart = await context.Carts.AsNoTracking().FirstOrDefaultAsync(x => x.MemberId == memberId);
        if (cart == null) return 0;
        return await context.CartItems.AsNoTracking().Where(x => x.CartId == cart.Id).SumAsync(x => x.Quantity);
    }
}
