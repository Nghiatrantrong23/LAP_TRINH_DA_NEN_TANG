namespace WebApi.Models;
public class SiteProvider(IHttpContextAccessor accessor, IConfiguration configuration) : BaseProvider(accessor)
{
    private MemberRepository? member;
    private AuthRepository? auth;
    private CategoryRepository? category;
    public MemberRepository Member => member ??= new MemberRepository(Context);
    public AuthRepository Auth => auth ??= new AuthRepository(Context, configuration);
    public CategoryRepository Category => category ??= new CategoryRepository(Context);
}
