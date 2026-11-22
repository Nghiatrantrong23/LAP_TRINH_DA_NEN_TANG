using System.ComponentModel.DataAnnotations.Schema;

namespace WebApi.Models;

[Table("InvoiceDetails")]
public class InvoiceDetail
{
    public long InvoiceId { get; set; }
    public int BikeId { get; set; }
    public short Quantity { get; set; }

    [Column(TypeName = "decimal(10,2)")]
    public decimal Price { get; set; }

    [ForeignKey("BikeId")]
    public virtual Bike? Bike { get; set; }
}
