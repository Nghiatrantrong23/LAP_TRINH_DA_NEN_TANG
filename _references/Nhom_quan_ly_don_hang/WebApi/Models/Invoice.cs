using System.ComponentModel.DataAnnotations.Schema;

namespace WebApi.Models;
[Table("Invoice")]
public class Invoice
{
    [Column("InvoiceId")]
    public long Id { get; set; }
    public string? MemberId { get; set; } = null!;
    public int StatusId { get; set; }
    [Column("InvoiceDate")]
    public DateTime? Dated { get; set; }

    [ForeignKey("StatusId")]
    public virtual Status? Status { get; set; }

    public virtual List<InvoiceDetail> Details { get; set; } = new();
}