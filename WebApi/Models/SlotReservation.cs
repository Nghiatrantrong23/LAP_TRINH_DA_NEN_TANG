using System.ComponentModel.DataAnnotations;

namespace WebApi.Models;

public class SlotReservation
{
    public long CourtSlotId
    {
        get; set;
    }
    public long OrderItemId
    {
        get; set;
    }
}
