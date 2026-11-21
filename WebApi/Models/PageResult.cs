namespace WebApi.Models;

public class PageResult<T>
{
    public IReadOnlyList<T> Items { get; set; } = new List<T>();
    public int PageIndex
    { get; set; }
    public int PageSize
    { get; set; }
    public int TotalItems
    { get; set; }
    public int TotalPages
    { get; set; }
}
