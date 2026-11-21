using Microsoft.EntityFrameworkCore;
using WebApi.Models;
namespace WebApi.Services;
public static class DatabaseSeeder
{
    public static async Task Run(SportsBookingContext db, IConfiguration config)
    {
        await db.Database.MigrateAsync();
        await using var tx = await db.Database.BeginTransactionAsync();
        foreach (var role in new[] { new Role { Id = 1, Name = "Member" }, new Role { Id = 2, Name = "Admin" } })
        {
            if (!await db.Roles.AnyAsync(x => x.Id == role.Id))
            {
                db.Roles.Add(role);
            }
        }

        await db.SaveChangesAsync();
        if (!await db.Members.AnyAsync(x => x.RoleId == 2 && !x.IsLocked))
        {
            var email = config["Seed:AdminEmail"] ?? "";
            var password = config["Seed:AdminPassword"] ?? "";
            if (!new System.ComponentModel.DataAnnotations.EmailAddressAttribute().IsValid(email) || password.Length < 12)
            {
                throw new InvalidOperationException("Set Seed:AdminEmail and a private Seed:AdminPassword of 12+ characters.");
            }

            Helper.ValidatePassword(password);
            var normalized = Helper.NormalizeEmail(email);
            if (await db.Members.AnyAsync(x => x.NormalizedEmail == normalized))
            {
                throw new InvalidOperationException("Seed email is already used. Existing accounts are never automatically promoted.");
            }

            var admin = new Member { Email = email.Trim(), NormalizedEmail = normalized, GivenName = "Quản trị", Surname = "SportBooking", RoleId = 2, PasswordHash = BCrypt.Net.BCrypt.HashPassword(password) };
            db.Members.Add(admin);
            db.Carts.Add(new Cart { MemberId = admin.Id });
        }
        var venue = await db.Venues.SingleOrDefaultAsync(x => x.Name == "SportBooking Demo");
        if (venue == null)
        {
            venue = new Venue { Name = "SportBooking Demo", Address = "Cập nhật địa chỉ cơ sở khi triển khai", Phone = "0900000000" };
            db.Venues.Add(venue);
            await db.SaveChangesAsync();
        }
        var names = new[] { "Cầu lông", "Pickleball", "Bóng đá mini", "Dịch vụ" };
        for (var i = 0; i < names.Length; i++)
        {
            if (!await db.Categories.AnyAsync(x => x.Name == names[i]))
            {
                db.Categories.Add(new Category { Name = names[i], DisplayOrder = i + 1 });
            }
        }

        await db.SaveChangesAsync();
        var categories = await db.Categories.ToDictionaryAsync(x => x.Name, x => x.Id);
        var samples = new[]{
            new Product{CategoryId=categories["Cầu lông"],VenueId=venue.Id,Name="Sân cầu lông 01",BasePrice=80000,Description="Sân trong nhà, thảm tiêu chuẩn."},
            new Product{CategoryId=categories["Pickleball"],VenueId=venue.Id,Name="Sân Pickleball 01",BasePrice=120000,Description="Sân có mái che."},
            new Product{CategoryId=categories["Bóng đá mini"],VenueId=venue.Id,Name="Sân bóng đá mini 01",BasePrice=250000,Description="Sân cỏ nhân tạo 5 người."},
            new Product{CategoryId=categories["Dịch vụ"],VenueId=venue.Id,Name="Nước suối",BasePrice=10000,Type="Service",Unit="chai"},
            new Product{CategoryId=categories["Dịch vụ"],VenueId=venue.Id,Name="Thuê vợt",BasePrice=30000,Type="Service",Unit="vợt/buổi"}
        };
        foreach (var sample in samples)
        {
            var product = await db.Products.SingleOrDefaultAsync(x => x.Name == sample.Name && x.VenueId == venue.Id);
            if (product == null)
            {
                product = sample;
                db.Products.Add(product);
                await db.SaveChangesAsync();
            }
            if (product.Type != "Court")
            {
                continue;
            }

            if (!await db.CourtProfiles.AnyAsync(x => x.ProductId == product.Id))
            {
                db.CourtProfiles.Add(new CourtProfile { ProductId = product.Id, Capacity = (short)(product.Name.Contains("bóng đá") ? 10 : 4), Indoor = !product.Name.Contains("bóng đá"), Surface = product.Name.Contains("bóng đá") ? "Cỏ nhân tạo" : "Thảm" });
            }

            await db.SaveChangesAsync();
            for (byte day = 0; day < 7; day++)
            {
                if (!await db.CourtSchedules.AnyAsync(x => x.CourtId == product.Id && x.DayOfWeek == day))
                {
                    db.CourtSchedules.Add(new CourtSchedule { CourtId = product.Id, DayOfWeek = day, OpenTime = new TimeOnly(6, 0), CloseTime = new TimeOnly(22, 0) });
                }

                if (!await db.CourtPriceRules.AnyAsync(x => x.CourtId == product.Id && x.DayOfWeek == day))
                {
                    db.CourtPriceRules.Add(new CourtPriceRule { CourtId = product.Id, DayOfWeek = day, StartTime = new TimeOnly(17, 0), EndTime = new TimeOnly(21, 0), PricePerHour = product.BasePrice * 1.5m, EffectiveFrom = new DateOnly(2026, 1, 1) });
                }
            }
            await db.SaveChangesAsync();
        }
        await db.SaveChangesAsync();
        await tx.CommitAsync();
    }
}
