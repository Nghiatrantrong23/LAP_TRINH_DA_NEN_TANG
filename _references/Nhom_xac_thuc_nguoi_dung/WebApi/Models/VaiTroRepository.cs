namespace WebApi.Models;

public class VaiTroRepository : BaseRepository
{
    public VaiTroRepository(DatSanTheThaoContext context) : base(context)
    {
    }

    public IEnumerable<VaiTro> GetRoles()
    {
        return context.VaiTros.ToList();
    }

    public VaiTro? GetRole(short id)
    {
        return context.VaiTros.Find(id);
    }

    public int Add(VaiTro obj)
    {
        if (context.VaiTros.Any(p => p.TenVaiTro == obj.TenVaiTro || p.MaVaiTro == obj.MaVaiTro))
            return -1; // Đã tồn tại tên hoặc mã vai trò

        context.VaiTros.Add(obj);
        return context.SaveChanges();
    }

    public int Update(VaiTro obj)
    {
        VaiTro? item = context.VaiTros.Find(obj.MaVaiTro);
        if (item is null) return -1;

        item.TenVaiTro = obj.TenVaiTro;
        context.VaiTros.Update(item);
        return context.SaveChanges();
    }

    public int Delete(short id)
    {
        // Không xóa 2 role cơ bản Admin (1) và Member (2)
        if (id <= 2) return -2;

        VaiTro? item = context.VaiTros.Find(id);
        if (item is null) return -1;

        // Nếu có thành viên đang giữ role này thì không cho xóa
        if (context.ThanhViens.Any(p => p.MaVaiTro == id))
            return -3;

        context.VaiTros.Remove(item);
        return context.SaveChanges();
    }
}

