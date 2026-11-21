namespace WebApi.Models;

public abstract class BaseRepository
{
    protected readonly SportsBookingContext context;

    public BaseRepository(SportsBookingContext context)
    {
        this.context = context;
    }
}
