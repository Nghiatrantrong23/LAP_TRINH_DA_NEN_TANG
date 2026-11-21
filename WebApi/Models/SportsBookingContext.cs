using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Storage.ValueConversion;
namespace WebApi.Models;
public class SportsBookingContext : DbContext
{
    public SportsBookingContext(DbContextOptions<SportsBookingContext> options) : base(options)
    {
    }

    public DbSet<Role> Roles => Set<Role>();
    public DbSet<Member> Members => Set<Member>();
    public DbSet<AuthSession> AuthSessions => Set<AuthSession>();
    public DbSet<EmailChallenge> EmailChallenges => Set<EmailChallenge>();
    public DbSet<Venue> Venues => Set<Venue>();
    public DbSet<Category> Categories => Set<Category>();
    public DbSet<Product> Products => Set<Product>();
    public DbSet<CourtProfile> CourtProfiles => Set<CourtProfile>();
    public DbSet<CourtSchedule> CourtSchedules => Set<CourtSchedule>();
    public DbSet<CourtPriceRule> CourtPriceRules => Set<CourtPriceRule>();
    public DbSet<CourtSlot> CourtSlots => Set<CourtSlot>();
    public DbSet<Cart> Carts => Set<Cart>();
    public DbSet<CartItem> CartItems => Set<CartItem>();
    public DbSet<Order> Orders => Set<Order>();
    public DbSet<OrderItem> OrderItems => Set<OrderItem>();
    public DbSet<OrderItemSlot> OrderItemSlots => Set<OrderItemSlot>();
    public DbSet<SlotReservation> SlotReservations => Set<SlotReservation>();
    public DbSet<OrderStatusHistory> OrderStatusHistories => Set<OrderStatusHistory>();
    public DbSet<CheckInToken> CheckInTokens => Set<CheckInToken>();
    public DbSet<Payment> Payments => Set<Payment>();
    public DbSet<MatchRoom> MatchRooms => Set<MatchRoom>();
    public DbSet<MatchRequest> MatchRequests => Set<MatchRequest>();
    public DbSet<FileDeletionJob> FileDeletionJobs => Set<FileDeletionJob>();
    protected override void OnModelCreating(ModelBuilder b)
    {
        b.Entity<Role>().Property(x => x.Id).ValueGeneratedNever();
        b.Entity<Role>().HasIndex(x => x.Name).IsUnique();
        b.Entity<Member>().HasOne(x => x.Role).WithMany().HasForeignKey(x => x.RoleId).OnDelete(DeleteBehavior.Restrict);
        b.Entity<Member>().HasIndex(x => x.NormalizedEmail).IsUnique();
        b.Entity<AuthSession>().HasIndex(x => x.RefreshTokenHash).IsUnique();
        b.Entity<Category>().HasIndex(x => x.Name).IsUnique();
        b.Entity<CourtProfile>().HasKey(x => x.ProductId);
        b.Entity<CourtProfile>().HasOne<Product>().WithOne().HasForeignKey<CourtProfile>(x => x.ProductId).OnDelete(DeleteBehavior.Restrict);
        b.Entity<CourtSchedule>().HasIndex(x => new { x.CourtId, x.DayOfWeek }).IsUnique();
        b.Entity<CourtSlot>().HasIndex(x => new { x.CourtId, x.PlayDate, x.StartTime }).IsUnique();
        b.Entity<Cart>().HasIndex(x => x.MemberId).IsUnique();
        b.Entity<Order>().HasIndex(x => x.OrderCode).IsUnique();
        b.Entity<Order>().HasIndex(x => new { x.MemberId, x.IdempotencyKey }).IsUnique();
        b.Entity<OrderItemSlot>().HasKey(x => new { x.OrderItemId, x.CourtSlotId });
        b.Entity<SlotReservation>().HasKey(x => x.CourtSlotId);
        b.Entity<SlotReservation>().HasOne<OrderItemSlot>().WithMany().HasForeignKey(x => new { x.OrderItemId, x.CourtSlotId }).OnDelete(DeleteBehavior.Restrict);
        b.Entity<CheckInToken>().HasIndex(x => x.TokenHash).IsUnique();
        b.Entity<Payment>().HasIndex(x => x.ExternalReference).IsUnique().HasFilter("[ExternalReference] IS NOT NULL");
        b.Entity<MatchRequest>().HasIndex(x => new { x.RoomId, x.MemberId }).IsUnique();
        b.Entity<MatchRoom>().HasIndex(x => x.OrderItemId).IsUnique().HasFilter("[Status] IN ('Open','Full')");
        b.Entity<Product>().HasIndex(x => new { x.CategoryId, x.IsActive, x.CreatedAt, x.Id });
        b.Entity<Order>().HasIndex(x => new { x.MemberId, x.CreatedAt, x.Id });
        b.Entity<Order>().HasIndex(x => new { x.Status, x.HoldExpiresAt });
        b.Entity<AuthSession>().HasOne<Member>().WithMany().HasForeignKey(x => x.MemberId).OnDelete(DeleteBehavior.Restrict);
        b.Entity<EmailChallenge>().HasOne<Member>().WithMany().HasForeignKey(x => x.MemberId).OnDelete(DeleteBehavior.Restrict);
        b.Entity<Product>().HasOne<Category>().WithMany().HasForeignKey(x => x.CategoryId).OnDelete(DeleteBehavior.Restrict);
        b.Entity<Product>().HasOne<Venue>().WithMany().HasForeignKey(x => x.VenueId).OnDelete(DeleteBehavior.Restrict);
        b.Entity<CourtSchedule>().HasOne<CourtProfile>().WithMany().HasForeignKey(x => x.CourtId).OnDelete(DeleteBehavior.Restrict);
        b.Entity<CourtPriceRule>().HasOne<CourtProfile>().WithMany().HasForeignKey(x => x.CourtId).OnDelete(DeleteBehavior.Restrict);
        b.Entity<CourtSlot>().HasOne<CourtProfile>().WithMany().HasForeignKey(x => x.CourtId).OnDelete(DeleteBehavior.Restrict);
        b.Entity<Cart>().HasOne<Member>().WithMany().HasForeignKey(x => x.MemberId).OnDelete(DeleteBehavior.Restrict);
        b.Entity<CartItem>().HasOne<Cart>().WithMany().HasForeignKey(x => x.CartId).OnDelete(DeleteBehavior.Restrict);
        b.Entity<CartItem>().HasOne<Product>().WithMany().HasForeignKey(x => x.ProductId).OnDelete(DeleteBehavior.Restrict);
        b.Entity<Order>().HasOne<Member>().WithMany().HasForeignKey(x => x.MemberId).OnDelete(DeleteBehavior.Restrict);
        b.Entity<Order>().HasOne<Venue>().WithMany().HasForeignKey(x => x.VenueId).OnDelete(DeleteBehavior.Restrict);
        b.Entity<OrderItem>().HasOne<Order>().WithMany().HasForeignKey(x => x.OrderId).OnDelete(DeleteBehavior.Restrict);
        b.Entity<OrderItem>().HasOne<Product>().WithMany().HasForeignKey(x => x.ProductId).OnDelete(DeleteBehavior.Restrict);
        b.Entity<OrderItemSlot>().HasOne<OrderItem>().WithMany().HasForeignKey(x => x.OrderItemId).OnDelete(DeleteBehavior.Restrict);
        b.Entity<OrderItemSlot>().HasOne<CourtSlot>().WithMany().HasForeignKey(x => x.CourtSlotId).OnDelete(DeleteBehavior.Restrict);
        b.Entity<OrderStatusHistory>().HasOne<Order>().WithMany().HasForeignKey(x => x.OrderId).OnDelete(DeleteBehavior.Restrict);
        b.Entity<OrderStatusHistory>().HasOne<Member>().WithMany().HasForeignKey(x => x.ChangedByMemberId).OnDelete(DeleteBehavior.Restrict);
        b.Entity<CheckInToken>().HasOne<Order>().WithMany().HasForeignKey(x => x.OrderId).OnDelete(DeleteBehavior.Restrict);
        b.Entity<CheckInToken>().HasOne<Member>().WithMany().HasForeignKey(x => x.UsedByMemberId).OnDelete(DeleteBehavior.Restrict);
        b.Entity<Payment>().HasOne<Order>().WithMany().HasForeignKey(x => x.OrderId).OnDelete(DeleteBehavior.Restrict);
        b.Entity<Payment>().HasOne<Member>().WithMany().HasForeignKey(x => x.VerifiedByMemberId).OnDelete(DeleteBehavior.Restrict);
        b.Entity<MatchRoom>().HasOne<OrderItem>().WithMany().HasForeignKey(x => x.OrderItemId).OnDelete(DeleteBehavior.Restrict);
        b.Entity<MatchRoom>().HasOne<Member>().WithMany().HasForeignKey(x => x.OwnerMemberId).OnDelete(DeleteBehavior.Restrict);
        b.Entity<MatchRequest>().HasOne<MatchRoom>().WithMany().HasForeignKey(x => x.RoomId).OnDelete(DeleteBehavior.Restrict);
        b.Entity<MatchRequest>().HasOne<Member>().WithMany().HasForeignKey(x => x.MemberId).OnDelete(DeleteBehavior.Restrict);
        b.Entity<MatchRequest>().HasOne<Member>().WithMany().HasForeignKey(x => x.ReviewedByMemberId).OnDelete(DeleteBehavior.Restrict);
        b.Entity<Product>().ToTable(t => t.HasCheckConstraint("CK_Product_Type", "[Type] IN ('Court','Service')"));
        b.Entity<Product>().ToTable(t => t.HasCheckConstraint("CK_Product_Price", "[BasePrice] >= 0"));
        b.Entity<CourtProfile>().ToTable(t => t.HasCheckConstraint("CK_CourtProfile_Capacity", "[Capacity] > 1"));
        b.Entity<CourtProfile>().ToTable(t => t.HasCheckConstraint("CK_CourtProfile_SlotMinutes", "[SlotMinutes] = 30"));
        b.Entity<CourtSchedule>().ToTable(t => t.HasCheckConstraint("CK_CourtSchedule_Day", "[DayOfWeek] BETWEEN 0 AND 6"));
        b.Entity<CourtSchedule>().ToTable(t => t.HasCheckConstraint("CK_CourtSchedule_Hours", "[IsClosed] = 1 OR [OpenTime] < [CloseTime]"));
        b.Entity<CourtPriceRule>().ToTable(t => t.HasCheckConstraint("CK_CourtPriceRule_Price", "[PricePerHour] >= 0"));
        b.Entity<CourtPriceRule>().ToTable(t => t.HasCheckConstraint("CK_CourtPriceRule_Day", "[DayOfWeek] BETWEEN 0 AND 6"));
        b.Entity<CourtPriceRule>().ToTable(t => t.HasCheckConstraint("CK_CourtPriceRule_Period", "[StartTime] < [EndTime] AND ([EffectiveTo] IS NULL OR [EffectiveFrom] <= [EffectiveTo])"));
        b.Entity<CourtSlot>().ToTable(t => t.HasCheckConstraint("CK_CourtSlot_Duration", "DATEDIFF(MINUTE,[StartTime],[EndTime]) = 30 AND DATEPART(MINUTE,[StartTime]) IN (0,30) AND DATEPART(SECOND,[StartTime]) = 0 AND DATEPART(SECOND,[EndTime]) = 0"));
        b.Entity<CartItem>().ToTable(t => t.HasCheckConstraint("CK_CartItem_Quantity", "[Quantity] > 0"));
        b.Entity<CartItem>().ToTable(t => t.HasCheckConstraint("CK_CartItem_Time", "([PlayDate] IS NULL AND [StartTime] IS NULL AND [SlotCount] IS NULL) OR ([PlayDate] IS NOT NULL AND [StartTime] IS NOT NULL AND [SlotCount] IS NOT NULL AND [SlotCount] > 0 AND [Quantity] = 1)"));
        b.Entity<Order>().ToTable(t => t.HasCheckConstraint("CK_Order_Money", "[TotalAmount] >= 0 AND [DepositAmount] >= 0 AND [DepositAmount] <= [TotalAmount]"));
        b.Entity<Order>().ToTable(t => t.HasCheckConstraint("CK_Order_Status", "[Status] IN ('PendingDeposit','Confirmed','Playing','Completed','Cancelled')"));
        b.Entity<OrderItem>().ToTable(t => t.HasCheckConstraint("CK_OrderItem_Money", "[Quantity] > 0 AND [LineTotal] >= 0 AND ([UnitPrice] IS NULL OR [UnitPrice] >= 0)"));
        b.Entity<OrderItemSlot>().ToTable(t => t.HasCheckConstraint("CK_OrderItemSlot_Price", "[UnitPrice] >= 0"));
        b.Entity<Payment>().ToTable(t => t.HasCheckConstraint("CK_Payment_Amount", "[Amount] > 0"));
        b.Entity<Payment>().ToTable(t => t.HasCheckConstraint("CK_Payment_Kind", "[Kind] IN ('Deposit','Balance','Refund')"));
        b.Entity<Payment>().ToTable(t => t.HasCheckConstraint("CK_Payment_Status", "[Status] IN ('Pending','Confirmed','Rejected')"));
        b.Entity<MatchRoom>().ToTable(t => t.HasCheckConstraint("CK_MatchRoom_Slots", "[NeededPlayers] > 0 AND [CostPerPerson] >= 0"));
        b.Entity<MatchRoom>().ToTable(t => t.HasCheckConstraint("CK_MatchRoom_Status", "[Status] IN ('Open','Full','Closed')"));
        b.Entity<MatchRequest>().ToTable(t => t.HasCheckConstraint("CK_MatchRequest_Status", "[Status] IN ('Pending','Approved','Rejected','Withdrawn')"));
        foreach (var type in b.Model.GetEntityTypes())
        {
            foreach (var p in type.GetProperties())
            {
                if (p.ClrType == typeof(decimal) || p.ClrType == typeof(decimal?))
                {
                    p.SetPrecision(18);
                    p.SetScale(2);
                }
                if (p.Name == "RowVersion")
                {
                    p.IsConcurrencyToken = true;
                    p.ValueGenerated = Microsoft.EntityFrameworkCore.Metadata.ValueGenerated.OnAddOrUpdate;
                }
                if (p.ClrType == typeof(DateTime))
                {
                    p.SetValueConverter(new ValueConverter<DateTime, DateTime>(v => v, v => DateTime.SpecifyKind(v, DateTimeKind.Utc)));
                }

                if (p.ClrType == typeof(TimeOnly) || p.ClrType == typeof(TimeOnly?))
                {
                    p.SetColumnType("time(0)");
                }
            }
        }
    }
}
