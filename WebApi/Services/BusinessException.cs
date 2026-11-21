namespace WebApi.Services;
public class BusinessException(int status,string code,string message) : Exception(message)
{
    public int Status { get; } = status;
    public string Code { get; } = code;
}
