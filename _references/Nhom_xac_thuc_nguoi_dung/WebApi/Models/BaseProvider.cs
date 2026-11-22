namespace WebApi.Models;

public abstract class BaseProvider
{
    DatSanTheThaoContext? context;
    IHttpContextAccessor accessor;

    public BaseProvider(IHttpContextAccessor accessor)
    {
        this.accessor = accessor;
    }

    protected DatSanTheThaoContext Context => context ??= accessor.HttpContext!.RequestServices.GetRequiredService<DatSanTheThaoContext>();
}
