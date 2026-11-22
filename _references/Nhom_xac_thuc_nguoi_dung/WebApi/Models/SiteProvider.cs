namespace WebApi.Models;

public class SiteProvider : BaseProvider
{
    public SiteProvider(IHttpContextAccessor accessor) : base(accessor)
    {
    }

    VaiTroRepository? vaiTro;
    public VaiTroRepository VaiTro => vaiTro ??= new VaiTroRepository(Context);

    ThanhVienRepository? thanhVien;
    public ThanhVienRepository ThanhVien => thanhVien ??= new ThanhVienRepository(Context);

    DonHangRepository? donHang;
    public DonHangRepository DonHang => donHang ??= new DonHangRepository(Context);
}
