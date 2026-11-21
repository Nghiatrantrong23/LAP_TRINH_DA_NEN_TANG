namespace WebApi.Models;
public abstract class BaseProvider(IHttpContextAccessor accessor)
{
    private SportsBookingContext? context;
    protected SportsBookingContext Context => context ??= accessor.HttpContext!.RequestServices.GetRequiredService<SportsBookingContext>();
}
