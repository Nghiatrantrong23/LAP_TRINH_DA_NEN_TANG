namespace WebApi.Services;
public static class CatalogHelper
{
    public static void RequireVersion(byte[] current, string? input)
    {
        if (string.IsNullOrWhiteSpace(input))
        {
            throw new BusinessException(400, "VERSION_REQUIRED", "Cần phiên bản dữ liệu mới nhất.");
        }

        if (Convert.ToBase64String(current) != input)
        {
            throw new BusinessException(409, "DATA_CHANGED", "Dữ liệu vừa thay đổi. Vui lòng tải lại.");
        }
    }
    public static void ValidatePage(int page, int size)
    {
        if (page < 1 || page > 1000000 || size < 1 || size > 100)
        {
            throw new BusinessException(400, "INVALID_PAGE", "Phân trang không hợp lệ.");
        }
    }
}
