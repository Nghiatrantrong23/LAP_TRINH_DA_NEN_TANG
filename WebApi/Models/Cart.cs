using System.ComponentModel.DataAnnotations;

namespace WebApi.Models;

public class Cart
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid MemberId
    { get; set; }
    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;
    public byte[] RowVersion { get; set; } = [];
}
