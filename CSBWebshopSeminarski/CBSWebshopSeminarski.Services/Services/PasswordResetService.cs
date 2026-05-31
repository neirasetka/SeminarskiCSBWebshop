using CBSWebshopSeminarski.Model.Requests;
using CBSWebshopSeminarski.Services.Interfaces;
using CBSWebshopSeminarski.Services.Services;
using CSBWebshopSeminarski.Core.Entities;
using CSBWebshopSeminarski.Database;
using Microsoft.EntityFrameworkCore;
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

        public PasswordResetService(CocoSunBagsWebshopDbContext db, RabbitMqMailPublisher mailPublisher)
        {
            _db = db;
            _mailPublisher = mailPublisher;
        }

        public async Task RequestResetAsync(RequestPasswordResetRequest request)
        {
            var user = await _db.Users.FirstOrDefaultAsync(u => u.Email == request.Email);
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
                Used = false
            };

            try
            {
                _mailPublisher.Publish(
                    sender: "no-reply@cocosunbags.local",
                    recipient: user.Email,
                    subject: "Reset lozinke - CocoSunBags",
                    content: $"Poštovani/a {user.Name},\n\n" +
                             $"Vaš kod za reset lozinke je: {token}\n\n" +
                             "Kod vrijedi 30 minuta.\n\n" +
                             "Ako niste zatražili reset, ignorirajte ovu poruku.\n\n" +
                             "CocoSunBags tim");
            }
            catch
            {
                return;
            }

            _db.PasswordResetTokens.Add(entity);
            await _db.SaveChangesAsync();
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

        private static string HashToken(string token)
        {
            var hash = SHA256.HashData(Encoding.UTF8.GetBytes(token));
            return Convert.ToHexString(hash);
        }
    }
}
