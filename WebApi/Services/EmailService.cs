using System.Net;
using System.Net.Mail;

namespace WebApi.Services;

public interface IEmailService
{
    Task<bool> SendOtpAsync(string toEmail, string subject, string otp);
    Task<bool> SendEmailAsync(string toEmail, string subject, string body);
}

public class EmailService : IEmailService
{
    private readonly IConfiguration _config;
    private readonly ILogger<EmailService> _logger;

    private readonly IWebHostEnvironment _environment;

    public EmailService(IConfiguration config, ILogger<EmailService> logger, IWebHostEnvironment environment)
    {
        _config = config;
        _logger = logger;
        _environment = environment;
    }

    public async Task<bool> SendOtpAsync(string toEmail, string subject, string otp)
    {
        var logOtp = _environment.IsDevelopment() && _config.GetValue<bool>("EmailSettings:LogOtp");
        if (logOtp)
        {
            Console.WriteLine($"[OTP CODE: {otp}]");
            if (string.IsNullOrWhiteSpace(_config["EmailSettings:Password"])) return true;
        }
        return await SendEmailAsync(toEmail, subject, $"Mã xác nhận của bạn là <strong>{otp}</strong>. Mã có hiệu lực trong 15 phút.") || logOtp;
    }

    public async Task<bool> SendEmailAsync(string toEmail, string subject, string body)
    {
        try
        {
            string host = _config["EmailSettings:SmtpServer"] ?? "smtp.gmail.com";
            int port = int.Parse(_config["EmailSettings:Port"] ?? "587");
            string senderEmail = _config["EmailSettings:SenderEmail"] ?? "noreply@sportbooking.com";
            string senderName = _config["EmailSettings:SenderName"] ?? "Sport Booking System";
            string password = _config["EmailSettings:Password"] ?? "";
            bool enableSsl = bool.Parse(_config["EmailSettings:EnableSsl"] ?? "true");

            using (SmtpClient client = new SmtpClient(host, port))
            {
                client.Credentials = new NetworkCredential(senderEmail, password);
                client.EnableSsl = enableSsl;

                MailMessage message = new MailMessage
                {
                    From = new MailAddress(senderEmail, senderName),
                    Subject = subject,
                    Body = body,
                    IsBodyHtml = true
                };
                message.To.Add(toEmail);

                await client.SendMailAsync(message);
            }

            _logger.LogInformation($"[EmailService] Sent email successfully to {toEmail}");
            return true;
        }
        catch (Exception ex)
        {
            _logger.LogWarning("Không gửi được email qua SMTP ({ErrorType}).", ex.GetType().Name);
            return false;
        }
    }
}
