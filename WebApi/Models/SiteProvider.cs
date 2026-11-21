namespace WebApi.Models;

public class SiteProvider : BaseProvider
{
    private readonly IConfiguration configuration;
    private MemberRepository? member;
    private AuthRepository? auth;
    private CategoryRepository? category;

    public SiteProvider(IHttpContextAccessor accessor, IConfiguration configuration) : base(accessor)
    {
        this.configuration = configuration;
    }

    public MemberRepository Member => member ??= new MemberRepository(Context);
    public AuthRepository Auth => auth ??= new AuthRepository(Context, configuration);
    public CategoryRepository Category => category ??= new CategoryRepository(Context);
}
