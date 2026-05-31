using CBSWebshopSeminarski.Model.Requests;
using CBSWebshopSeminarski.Services.Interfaces;
using CSBWebshopSeminarski.Core.Entities;
using CSBWebshopSeminarski.Database;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using System.Security.Cryptography;
using System.Text;

using CBSWebshopSeminarski.Services;
using CBSWebshopSeminarski.Services.Exceptions;

namespace CBSWebshopSeminarski.Services.Services
{
    public class PasswordResetService : IPasswordResetService
    {
        private const int MaxResetRequestsPerEmailWindow = 3;
        private static readonly TimeSpan ResetRequestWindow = TimeSpan.FromMinutes(15);

        private readonly CocoSunBagsWebshopDbContext _db;
        private readonly RabbitMqMailPublisher _mailPublisher;
        private readonly EmailService _emailService;
        private readonly ILogger<PasswordResetService> _logger;

        public PasswordResetService(
            CocoSunBagsWebshopDbContext db,
            RabbitMqMailPublisher mailPublisher,
            EmailService emailService,
            ILogger<PasswordResetService> logger)
        {
            _db = db;
            _mailPublisher = mailPublisher;
            _emailService = emailService;
            _logger = logger;
        }

        public async Task RequestResetAsync(RequestPasswordResetRequest request)
        {
            var email = request.Email?.Trim();
            if (string.IsNullOrWhiteSpace(email))
                return;

            var normalizedEmail = email.ToLowerInvariant();
            var user = await _db.Users
                .FirstOrDefaultAsync(u => u.Email != null && u.Email.ToLower() == normalizedEmail);
            if (user == null)
                return;

            var windowStart = DateTime.UtcNow.Subtract(ResetRequestWindow);
            var recentRequests = await _db.PasswordResetTokens
                .CountAsync(t => t.UserID == user.UserID && t.CreatedAt >= windowStart);
            if (recentRequests >= MaxResetRequestsPerEmailWindow)
                return;

            var activeTokens = await _db.PasswordResetTokens
                .Where(t => t.UserID == user.UserID && !t.Used)
                .ToListAsync();
            foreach (var activeToken in activeTokens)
                activeToken.Used = true;

            var token = Convert.ToHexString(RandomNumberGenerator.GetBytes(32));
            var entity = new PasswordResetTokens
            {
                UserID = user.UserID,
                Token = HashToken(token),
                ExpiresAt = DateTime.UtcNow.AddMinutes(30),
                Used = false,
                CreatedAt = DateTime.UtcNow
            };

            _db.PasswordResetTokens.Add(entity);
            await _db.SaveChangesAsync();

            var subject = "Reset lozinke - CocoSunBags";
            var content = $"Poštovani/a {user.Name},\n\n" +
                          $"Vaš kod za reset lozinke je: {token}\n\n" +
                          "Kod vrijedi 30 minuta.\n\n" +
                          "Ako niste zatražili reset, ignorirajte ovu poruku.\n\n" +
                          "CocoSunBags tim";

            await TrySendResetEmailAsync(user.Email, subject, content);
        }

        public async Task ResetPasswordAsync(ResetPasswordRequest request)
        {
            if (request.NewPassword != request.ConfirmPassword)
                throw new ValidationException("Lozinke se ne podudaraju.");

            var tokenHash = HashToken(request.Token);
            var tokenEntity = await _db.PasswordResetTokens
                .Include(t => t.User)
                .FirstOrDefaultAsync(t => t.Token == tokenHash && !t.Used && t.ExpiresAt > DateTime.UtcNow);

            if (tokenEntity == null)
                throw new ValidationException("Token je nevažeći ili je istekao.");

            await _db.ExecuteInTransactionAsync(async () =>
            {
                var user = tokenEntity.User;
                user.PasswordSalt = UsersService.GenerateSalt();
                user.PasswordHash = UsersService.GenerateHash(user.PasswordSalt, request.NewPassword);

                var remainingTokens = await _db.PasswordResetTokens
                    .Where(t => t.UserID == user.UserID && !t.Used)
                    .ToListAsync();
                foreach (var remainingToken in remainingTokens)
                    remainingToken.Used = true;

                await _db.SaveChangesAsync();
            });
        }

        private async Task TrySendResetEmailAsync(string recipient, string subject, string content)
        {
            try
            {
                await _emailService.SendEmailAsync(recipient, subject, content);
                _logger.LogInformation("Password reset email sent via SMTP to {Recipient}.", recipient);
                return;
            }
            catch (Exception ex)
            {
                _logger.LogWarning(ex, "Direct SMTP failed for password reset; trying RabbitMQ queue.");
            }

            try
            {
                _mailPublisher.Publish(
                    sender: string.Empty,
                    recipient: recipient,
                    subject: subject,
                    content: content);
            }
            catch (Exception ex)
            {
                _logger.LogWarning(ex,
                    "RabbitMQ publish failed for password reset email to {Recipient}. Token was saved in database.",
                    recipient);
            }
        }

        private static string HashToken(string token)
        {
            var hash = SHA256.HashData(Encoding.UTF8.GetBytes(token));
            return Convert.ToHexString(hash);
        }
    }
}
