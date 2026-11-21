using Microsoft.EntityFrameworkCore;

namespace WebApi.Models;

public class DatSanTheThaoContext : DbContext
{
    public DatSanTheThaoContext(DbContextOptions<DatSanTheThaoContext> options) : base(options) { }

    public DbSet<VaiTro> VaiTros { get; set; } = null!;
    public DbSet<ThanhVien> ThanhViens { get; set; } = null!;
    public DbSet<PhienDangNhap> PhienDangNhaps { get; set; } = null!;
    public DbSet<MaXacThucEmail> MaXacThucEmails { get; set; } = null!;

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);

        modelBuilder.Entity<VaiTro>(entity =>
        {
            entity.HasIndex(p => p.TenVaiTro).IsUnique();
        });

        modelBuilder.Entity<ThanhVien>(entity =>
        {
            entity.HasIndex(p => p.EmailChuanHoa).IsUnique();
        });

        modelBuilder.Entity<PhienDangNhap>(entity =>
        {
            entity.HasIndex(p => p.RefreshTokenHash).IsUnique();
        });
    }
}

