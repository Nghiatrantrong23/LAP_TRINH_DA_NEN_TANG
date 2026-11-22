using Microsoft.Data.SqlClient;
using Microsoft.EntityFrameworkCore;

namespace WebApi.Models;

public class InvoiceRepository : BaseRepository
{
    public InvoiceRepository(TrekBikesContext context) : base(context)
    {
    }

    // 2. Cập nhật trạng thái đơn hàng (Bắt buộc - 0.50đ)
    public int Update(long id, short statusId)
    {
        Invoice? obj = context.Invoices.Find(id);
        if(obj is null) return -1;
        obj.StatusId = statusId;
        context.Update(obj);
        return context.SaveChanges();
    }

    public int Add(Invoice obj)
    {
        return context.Database.ExecuteSqlRaw("AddInvoice @InvoiceId, @MemberId, @StatusId", new SqlParameter[]
        {
            new SqlParameter("@MemberId", obj.MemberId),
            new SqlParameter("@InvoiceId", obj.Id),
            new SqlParameter("@StatusId", obj.StatusId),
        });
    }

    // 1. Hiển thị danh sách đơn hàng (0.25đ)
    // 3. Tìm kiếm đơn hàng (0.25đ)
    // 4. Lọc đơn hàng theo ngày (0.25đ)
    public IEnumerable<Invoice> GetInvoices(string? search = null, DateTime? fromDate = null, DateTime? toDate = null, int? statusId = null)
    {
        IQueryable<Invoice> query = context.Invoices
            .Include(p => p.Status)
            .Include(p => p.Details)
            .ThenInclude(d => d.Bike)
            .AsNoTracking();

        // Tìm kiếm theo Mã hóa đơn (InvoiceId) hoặc Mã thành viên/email (MemberId)
        if (!string.IsNullOrWhiteSpace(search))
        {
            string s = search.Trim();
            if (long.TryParse(s, out long id))
            {
                query = query.Where(p => p.Id == id || (p.MemberId != null && p.MemberId.Contains(s)));
            }
            else
            {
                query = query.Where(p => p.MemberId != null && p.MemberId.Contains(s));
            }
        }

        // Lọc theo trạng thái
        if (statusId.HasValue && statusId.Value > 0)
        {
            query = query.Where(p => p.StatusId == statusId.Value);
        }

        // Lọc theo khoảng ngày tạo hóa đơn
        if (fromDate.HasValue)
        {
            DateTime start = fromDate.Value.Date;
            query = query.Where(p => p.Dated >= start);
        }

        if (toDate.HasValue)
        {
            DateTime end = toDate.Value.Date.AddDays(1).AddTicks(-1);
            query = query.Where(p => p.Dated <= end);
        }

        return query.OrderByDescending(p => p.Dated).ToList();
    }

    public IEnumerable<Invoice> GetInvoices(string memberId)
    {
        return context.Invoices
            .Include(p => p.Status)
            .Include(p => p.Details)
            .ThenInclude(d => d.Bike)
            .Where(p => p.MemberId == memberId)
            .OrderByDescending(p => p.Dated)
            .ToList();
    }

    public Invoice? GetInvoice(long id)
    {
        return context.Invoices
            .Include(p => p.Status)
            .Include(p => p.Details)
            .ThenInclude(d => d.Bike)
            .AsNoTracking()
            .FirstOrDefault(p => p.Id == id);
    }
}