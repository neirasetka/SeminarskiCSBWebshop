using CBSWebshopSeminarski.Model.DTOs;
using CBSWebshopSeminarski.Model.Requests;
using CBSWebshopSeminarski.Services.Interfaces;
using CSBWebshopSeminarski.Core.Entities;
using CSBWebshopSeminarski.Database;
using Microsoft.EntityFrameworkCore;

using CBSWebshopSeminarski.Services.Exceptions;

namespace CBSWebshopSeminarski.Services.Services
{
    public class NewsletterService : INewsletterService
    {
        private readonly CocoSunBagsWebshopDbContext _context;

        public NewsletterService(CocoSunBagsWebshopDbContext context)
        {
            _context = context;
        }

        public async Task<NewsletterSubscriptionResult> SubscribeAsync(NewsletterSubscriptionRequest request)
        {
            var normalizedEmail = request.Email.Trim().ToLowerInvariant();
            var existing = await _context.Subscribers.FirstOrDefaultAsync(s => s.Email.ToLower() == normalizedEmail);

            if (existing == null)
            {
                existing = new Subscribers
                {
                    Email = normalizedEmail,
                    IsSubscribedToGiveaway = request.IsSubscribedToGiveaway ?? false,
                    IsSubscribedToNewCollections = request.IsSubscribedToNewCollections ?? false
                };
                _context.Subscribers.Add(existing);
            }
            else
            {
                if (request.IsSubscribedToGiveaway.HasValue)
                    existing.IsSubscribedToGiveaway = request.IsSubscribedToGiveaway.Value;
                if (request.IsSubscribedToNewCollections.HasValue)
                    existing.IsSubscribedToNewCollections = request.IsSubscribedToNewCollections.Value;
            }

            await _context.SaveChangesAsync();

            return new NewsletterSubscriptionResult
            {
                Email = existing.Email,
                IsSubscribedToGiveaway = existing.IsSubscribedToGiveaway,
                IsSubscribedToNewCollections = existing.IsSubscribedToNewCollections
            };
        }

        public async Task<NewsletterSubscriptionStatusResult> GetSubscriptionStatusAsync(string email)
        {
            if (string.IsNullOrWhiteSpace(email))
                throw new ValidationException("Email je obavezan.");

            var normalizedEmail = email.Trim().ToLowerInvariant();
            var subscriber = await _context.Subscribers.AsNoTracking()
                .FirstOrDefaultAsync(s => s.Email.ToLower() == normalizedEmail);

            return new NewsletterSubscriptionStatusResult
            {
                Email = normalizedEmail,
                IsSubscribedToGiveaway = subscriber?.IsSubscribedToGiveaway ?? false,
                IsSubscribedToNewCollections = subscriber?.IsSubscribedToNewCollections ?? false
            };
        }

        public async Task<IReadOnlyList<NewsletterSubscriberDto>> GetSubscribersAsync()
        {
            return await _context.Subscribers
                .AsNoTracking()
                .Where(s => s.IsSubscribedToNewCollections)
                .OrderBy(s => s.Email)
                .Select(s => new NewsletterSubscriberDto
                {
                    Id = s.Id,
                    Email = s.Email,
                    IsSubscribedToGiveaway = s.IsSubscribedToGiveaway,
                    IsSubscribedToNewCollections = s.IsSubscribedToNewCollections
                })
                .ToListAsync();
        }
    }
}
