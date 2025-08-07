using CSBWebshopSeminarski.Database;
using Microsoft.EntityFrameworkCore;

namespace CBSWebshopSeminarski.Services.Services
{
    public class NotificationsService
    {
        private readonly CocoSunBagsWebshopDbContext _context;
        private readonly EmailService _emailService;

        public NotificationsService(CocoSunBagsWebshopDbContext context, EmailService emailService)
        {
            _context = context;
            _emailService = emailService;
        }

        public async Task NotifySubscribersAboutGiveaway(string subject, string message)
        {
            var subscribers = await _context.Subscribers
                .Where(s => s.IsSubscribedToGiveaway)
                .ToListAsync();

            foreach (var subscriber in subscribers)
            {
                await _emailService.SendEmailAsync(subscriber.Email, subject, message);
            }
        }

        public async Task NotifySubscribersAboutNewCollection(string subject, string message)
        {
            var subscribers = await _context.Subscribers
                .Where(s => s.IsSubscribedToNewCollections)
                .ToListAsync();

            foreach (var subscriber in subscribers)
            {
                await _emailService.SendEmailAsync(subscriber.Email, subject, message);
            }
        }
    }
}
