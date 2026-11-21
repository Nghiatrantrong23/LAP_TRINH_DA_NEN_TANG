namespace WebApi.Models;

public abstract class BaseRepository
{
    protected DatSanTheThaoContext context;

    public BaseRepository(DatSanTheThaoContext context)
    {
        this.context = context;
    }
}
