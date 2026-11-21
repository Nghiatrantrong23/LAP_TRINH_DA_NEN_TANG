namespace WebApi.Models;

public abstract class BaseProvider
{
    private SportsBookingContext? context;
    private readonly IHttpContextAccessor accessor;

    public BaseProvider(IHttpContextAccessor accessor)
    {
        this.accessor = accessor;
    }

    protected SportsBookingContext Context => context ??= accessor.HttpContext!.RequestServices.GetRequiredService<SportsBookingContext>();
}
