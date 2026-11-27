using Microsoft.EntityFrameworkCore;
using WebApi.Models;
namespace WebApi.Services;
public class FileCleanupWorker : BackgroundService
{
    private readonly IServiceScopeFactory scopes;
    private readonly FileStorage storage;
    private readonly ILogger<FileCleanupWorker> logger;
    public FileCleanupWorker(IServiceScopeFactory scopes, FileStorage storage, ILogger<FileCleanupWorker> logger)
    {
        this.scopes = scopes;
        this.storage = storage;
        this.logger = logger;
    }
    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        using var timer = new PeriodicTimer(TimeSpan.FromSeconds(5));
        while (await timer.WaitForNextTickAsync(stoppingToken))
        {
            try
            {
                using var scope = scopes.CreateScope();
                var db = scope.ServiceProvider.GetRequiredService<SportsBookingContext>();
                var jobs = await db.FileDeletionJobs.Where(x => x.CompletedAt == null && (x.NextAttemptAt == null || x.NextAttemptAt <= DateTime.UtcNow)).OrderBy(x => x.Id).Take(50).ToListAsync(stoppingToken);
                foreach (var job in jobs)
                {
                    await storage.Clean(db, job);
                }

                await db.SaveChangesAsync(stoppingToken);
            }
            catch (Exception error) when (!stoppingToken.IsCancellationRequested) { logger.LogWarning(error, "Image cleanup will retry."); }
        }
    }
}
