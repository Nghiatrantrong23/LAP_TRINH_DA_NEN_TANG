namespace WebApi.Models;
public abstract class BaseRepository(SportsBookingContext context)
{
    protected readonly SportsBookingContext context = context;
}
