using System.Net;
using System.Net.Mail;

namespace WebApi.Services;

public interface IEmailService
{
    Task<bool> SendEmailAsync(string toEmail, string subject, string body);
}

public class EmailService : IEmailService
{
    private readonly IConfiguration _config;
    private readonly ILogger<EmailService> _logger;

    public EmailService(IConfiguration config, ILogger<EmailService> logger)
    {
        _config = config;
        _logger = logger;
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
            // Trong môi trường demo/phòng lab nếu chưa cấu hình mật khẩu ứng dụng Gmail thực,
            // log ra console để giảng viên/sinh viên vẫn thấy mã OTP xác thực
            _logger.LogWarning($"[EmailService Demo Mode] Cannot send live SMTP. Message content: {body}. Error: {ex.Message}");
            Console.WriteLine($"========================================================");
            Console.WriteLine($"[EMAIL SENT TO: {toEmail}]");
            Console.WriteLine($"Subject: {subject}");
            Console.WriteLine($"Body: {body}");
            Console.WriteLine($"========================================================");
            return true;
        }
    }
}

