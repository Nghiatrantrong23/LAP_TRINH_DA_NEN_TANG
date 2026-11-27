using System.ComponentModel.DataAnnotations;

namespace WebApi.Models;

public class FileDeletionJob
{
    public long Id
    { get; set; }
    [MaxLength(500)] public string RelativePath { get; set; } = "";
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime? CompletedAt
    { get; set; }
    public int Attempts
    { get; set; }
    public DateTime? NextAttemptAt
    { get; set; }
    [MaxLength(1000)]
    public string? LastError
    { get; set; }
}
