using MailKit.Net.Smtp;
using MailKit.Security;
using MailKit;
using MimeKit;

namespace CBSWebshopSeminarski.Services.Services
{
    public class EmailService
    {
        private readonly string _smtpServer;
        private readonly int _smtpPort;
        private readonly string _smtpUser;
        private readonly string _smtpPass;

        public EmailService(string smtpServer, int smtpPort, string smtpUser, string smtpPass)
        {
            _smtpServer = (smtpServer ?? string.Empty).Trim();
            _smtpPort = smtpPort;
            _smtpUser = (smtpUser ?? string.Empty).Trim();
            // Gmail "app password" is 16 characters; Google often shows it in groups — auth expects no spaces.
            _smtpPass = (smtpPass ?? string.Empty).Replace(" ", string.Empty).Trim();
        }

        public async Task SendEmailAsync(string recipientEmail, string subject, string message)
        {
            var email = new MimeMessage();
            email.From.Add(MailboxAddress.Parse(_smtpUser));
            email.To.Add(MailboxAddress.Parse(recipientEmail));
            email.Subject = subject;
            email.Body = new TextPart("plain") { Text = message };

            using var smtp = new SmtpClient();
            try
            {
                await smtp.ConnectAsync(_smtpServer, _smtpPort, SecureSocketOptions.StartTls);
                // Gmail app-password auth uses basic mechanisms; XOAUTH2 can cause auth mismatch.
                smtp.AuthenticationMechanisms.Remove("XOAUTH2");
                await smtp.AuthenticateAsync(_smtpUser, _smtpPass);
                await smtp.SendAsync(email);
            }
            catch (AuthenticationException ex)
            {
                throw new InvalidOperationException(
                    $"SMTP autentikacija nije uspjela za korisnika '{_smtpUser}'. " +
                    "Provjerite App Password i da je 2FA uključena na Gmail nalogu.",
                    ex);
            }
            catch (SmtpCommandException ex)
            {
                throw new InvalidOperationException(
                    $"SMTP command error ({ex.StatusCode}): {ex.Message}",
                    ex);
            }
            catch (SmtpProtocolException ex)
            {
                throw new InvalidOperationException(
                    $"SMTP protocol error: {ex.Message}",
                    ex);
            }
            finally
            {
                if (smtp.IsConnected)
                {
                    await smtp.DisconnectAsync(true);
                }
            }
        }
    }
}
