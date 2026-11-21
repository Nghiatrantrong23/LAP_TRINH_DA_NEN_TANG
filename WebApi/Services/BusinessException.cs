namespace WebApi.Services;

public class BusinessException : Exception
{
    public int Status
    {
        get;
    }
    public string Code
    {
        get;
    }

    public BusinessException(int status, string code, string message) : base(message)
    {
        Status = status;
        Code = code;
    }
}
