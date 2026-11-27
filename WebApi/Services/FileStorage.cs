using System.Buffers.Binary;
using Microsoft.EntityFrameworkCore;
using WebApi.Models;
namespace WebApi.Services;
public class FileStorage
{
    private readonly IWebHostEnvironment environment;
    private readonly IServiceScopeFactory scopes;
    public FileStorage(IWebHostEnvironment environment, IServiceScopeFactory scopes)
    {
        this.environment = environment;
        this.scopes = scopes;
    }
    public string Resolve(string relative)
    {
        if (!relative.StartsWith("/uploads/categories/") && !relative.StartsWith("/uploads/products/"))
        {
            throw new InvalidOperationException("Invalid upload folder.");
        }

        string root = Path.GetFullPath(Path.Combine(environment.WebRootPath, "uploads")) + Path.DirectorySeparatorChar;
        string path = Path.GetFullPath(Path.Combine(environment.WebRootPath, relative.TrimStart('/')));
        if (!path.StartsWith(root, OperatingSystem.IsWindows() ? StringComparison.OrdinalIgnoreCase : StringComparison.Ordinal))
        {
            throw new InvalidOperationException("Path escapes upload folder.");
        }

        return path;
    }
    public async Task<string?> Stage(IFormFile? image, string folder)
    {
        if (image == null)
        {
            return null;
        }

        if (folder != "categories" && folder != "products")
        {
            throw new InvalidOperationException("Invalid folder.");
        }

        if (image.Length < 24 || image.Length > 5 * 1024 * 1024)
        {
            throw new BusinessException(400, "INVALID_IMAGE", "Ảnh hợp lệ cần nhỏ hơn hoặc bằng 5 MB.");
        }

        using var memory = new MemoryStream();
        await image.CopyToAsync(memory);
        byte[] bytes = memory.ToArray();
        bool png = bytes.Length >= 33 && bytes.Take(8).SequenceEqual(new byte[] { 137, 80, 78, 71, 13, 10, 26, 10 })
            && System.Text.Encoding.ASCII.GetString(bytes, 12, 4) == "IHDR"
            && BinaryPrimitives.ReadUInt32BigEndian(bytes.AsSpan(16, 4)) is > 0 and <= 10000
            && BinaryPrimitives.ReadUInt32BigEndian(bytes.AsSpan(20, 4)) is > 0 and <= 10000;
        bool jpg = bytes[0] == 255 && bytes[1] == 216 && bytes[2] == 255 && bytes[^2] == 255 && bytes[^1] == 217;
        bool webp = bytes.Length >= 30 && System.Text.Encoding.ASCII.GetString(bytes, 0, 4) == "RIFF" && System.Text.Encoding.ASCII.GetString(bytes, 8, 4) == "WEBP";
        if (!png && !jpg && !webp)
        {
            throw new BusinessException(415, "INVALID_IMAGE", "Chỉ chấp nhận PNG, JPEG hoặc WebP; không dựa vào tên file.");
        }

        string relative = "/uploads/" + folder + "/" + Guid.NewGuid().ToString("N") + (png ? ".png" : jpg ? ".jpg" : ".webp");
        // Persist orphan cleanup before writing. Successful attachment removes this job in its DB transaction.
        using (var scope = scopes.CreateScope())
        {
            var db = scope.ServiceProvider.GetRequiredService<SportsBookingContext>();
            db.FileDeletionJobs.Add(new FileDeletionJob { RelativePath = relative, NextAttemptAt = DateTime.UtcNow.AddHours(24) });
            await db.SaveChangesAsync();
        }
        try
        {
            string path = Resolve(relative);
            Directory.CreateDirectory(Path.GetDirectoryName(path)!);
            await using var file = new FileStream(path, FileMode.CreateNew, FileAccess.Write, FileShare.None);
            await file.WriteAsync(bytes);
            return relative;
        }
        catch { await Discard(relative); throw; }
    }
    public async Task Discard(string? relative)
    {
        if (relative == null)
        {
            return;
        }

        try
        {
            using var scope = scopes.CreateScope();
            var db = scope.ServiceProvider.GetRequiredService<SportsBookingContext>();
            var job = await db.FileDeletionJobs.FirstOrDefaultAsync(x => x.RelativePath == relative && x.CompletedAt == null);
            if (job == null)
            {
                return;
            }

            await Clean(db, job);
            await db.SaveChangesAsync();
        }
        catch { /* A durable job is already queued for retry. */ }
    }
    public async Task Clean(SportsBookingContext db, FileDeletionJob job)
    {
        try
        {
            bool used = await db.Categories.AnyAsync(x => x.ImagePath == job.RelativePath) || await db.Products.AnyAsync(x => x.ImagePath == job.RelativePath);
            if (!used)
            {
                File.Delete(Resolve(job.RelativePath));
            }

            job.CompletedAt = DateTime.UtcNow;
            job.LastError = null;
        }
        catch (Exception error)
        {
            job.Attempts++;
            job.LastError = error.Message.Length > 1000 ? error.Message[..1000] : error.Message;
            job.NextAttemptAt = DateTime.UtcNow.AddSeconds(Math.Min(3600, 5 * Math.Pow(2, Math.Min(job.Attempts, 9))));
        }
    }
}
