using WebApi.Services;

namespace WebApi.Models;

public class SiteProvider : BaseProvider
{
    private readonly IConfiguration configuration;
    private MemberRepository? member;
    private AuthRepository? auth;
    private CategoryRepository? category;
    private ProductRepository? product;
    private OrderRepository? order;
    private CartRepository? cart;
    private readonly FileStorage images;

    public SiteProvider(IHttpContextAccessor accessor, IConfiguration configuration, FileStorage images) : base(accessor)
    {
        this.configuration = configuration;
        this.images = images;
    }

    public MemberRepository Member => member ??= new MemberRepository(Context);
    public AuthRepository Auth => auth ??= new AuthRepository(Context, configuration);
    public CategoryRepository Category => category ??= new CategoryRepository(Context, images);
    public ProductRepository Product => product ??= new ProductRepository(Context, images);
    public OrderRepository Order => order ??= new OrderRepository(Context);
    public CartRepository Cart => cart ??= new CartRepository(Context);
}
