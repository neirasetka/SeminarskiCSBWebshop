using CSBWebshopSeminarski.Core.Entities;
using CSBWebshopSeminarski.Database;
using Microsoft.EntityFrameworkCore;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Security.Cryptography;
using System.ComponentModel.DataAnnotations;

namespace CBSWebshopSeminarski.Services.Services
{
    public class GiveawaysService
    {
        private readonly CocoSunBagsWebshopDbContext _context;
        private readonly EmailService _emailService;

        public GiveawaysService(CocoSunBagsWebshopDbContext context, EmailService emailService)
        {
            _context = context;
            _emailService = emailService;
        }

        public async Task<Giveaways> CreateGiveawayAsync(string title, DateTime startDate, DateTime endDate)
        {
            if (string.IsNullOrWhiteSpace(title))
            {
                throw new ArgumentException("Title is required", nameof(title));
            }
            // Normalize to UTC
            var startUtc = DateTime.SpecifyKind(startDate, DateTimeKind.Utc).ToUniversalTime();
            var endUtc = DateTime.SpecifyKind(endDate, DateTimeKind.Utc).ToUniversalTime();

            if (endUtc <= startUtc)
            {
                throw new ArgumentException("EndDate must be after StartDate");
            }
            var giveaway = new Giveaways
            {
                Title = title.Trim(),
                StartDate = startUtc,
                EndDate = endUtc,
                IsClosed = false
            };

            _context.Giveaways.Add(giveaway);
            await _context.SaveChangesAsync();

            return giveaway;
        }

        public async Task<Participants> RegisterParticipantAsync(int giveawayId, string name, string email)
        {
            if (string.IsNullOrWhiteSpace(email))
            {
                throw new ArgumentException("Email is required", nameof(email));
            }
            if (email.Length > 254)
            {
                throw new ArgumentException("Email too long", nameof(email));
            }
            try
            {
                var _ = new EmailAddressAttribute().IsValid(email) ? true : throw new ArgumentException("Invalid email format", nameof(email));
            }
            catch
            {
                throw new ArgumentException("Invalid email format", nameof(email));
            }

            var normalizedEmail = email.Trim().ToLowerInvariant();

            var giveaway = await _context.Giveaways.FindAsync(giveawayId)
                           ?? throw new InvalidOperationException("Giveaway not found");
            var now = DateTime.UtcNow;
            if (now < giveaway.StartDate || now > giveaway.EndDate || giveaway.IsClosed)
            {
                throw new InvalidOperationException("Giveaway is not accepting entries");
            }
            var alreadyExists = await _context.Participants.AnyAsync(p => p.GiveawayId == giveawayId && p.Email == normalizedEmail);
            if (alreadyExists)
            {
                throw new InvalidOperationException("Participant with this email already registered for this giveaway");
            }

            var participant = new Participants
            {
                Name = string.IsNullOrWhiteSpace(name) ? null : name.Trim(),
                Email = normalizedEmail,
                GiveawayId = giveawayId,
                EntryDate = DateTime.UtcNow
            };

            _context.Participants.Add(participant);
            await _context.SaveChangesAsync();

            return participant;
        }

        public async Task<Participants?> SelectRandomWinnerAsync(int giveawayId)
        {
            var giveaway = await _context.Giveaways.FindAsync(giveawayId)
                           ?? throw new InvalidOperationException("Giveaway not found");
            if (DateTime.UtcNow < giveaway.EndDate)
            {
                throw new InvalidOperationException("Giveaway has not ended yet");
            }
            var participants = await _context.Participants
                                             .Where(p => p.GiveawayId == giveawayId)
                                             .ToListAsync();
            if (participants.Count == 0)
            {
                return null;
            }

            var index = RandomNumberGenerator.GetInt32(participants.Count);
            return participants[index];
        }

        public async Task NotifyWinnerAsync(Participants winner)
        {
            if (!string.IsNullOrWhiteSpace(winner.Email))
            {
                await _emailService.SendEmailAsync(winner.Email, "Congratulations, You Are a Winner!", "You have won the giveaway!");
            }
        }

        public async Task<Participants?> DrawAndPersistWinnerAsync(int giveawayId)
        {
            // Use retry on concurrency conflict
            const int maxRetries = 3;
            int attempt = 0;
            while (true)
            {
                attempt++;
                using var tx = await _context.Database.BeginTransactionAsync();

                var giveaway = await _context.Giveaways
                    .Include(g => g.Participants)
                    .FirstOrDefaultAsync(g => g.Id == giveawayId)
                    ?? throw new InvalidOperationException("Giveaway not found");

                if (giveaway.IsClosed)
                {
                    if (giveaway.WinnerParticipantId.HasValue)
                    {
                        var existingWinner = await _context.Participants.FindAsync(giveaway.WinnerParticipantId.Value);
                        await tx.CommitAsync();
                        return existingWinner;
                    }
                    await tx.CommitAsync();
                    return null;
                }

                if (DateTime.UtcNow < giveaway.EndDate)
                {
                    await tx.RollbackAsync();
                    throw new InvalidOperationException("Giveaway has not ended yet");
                }

                var participants = giveaway.Participants.ToList();
                if (participants.Count == 0)
                {
                    giveaway.IsClosed = true;
                    try
                    {
                        await _context.SaveChangesAsync();
                        await tx.CommitAsync();
                        return null;
                    }
                    catch (DbUpdateConcurrencyException) when (attempt < maxRetries)
                    {
                        await tx.RollbackAsync();
                        _context.ChangeTracker.Clear();
                        continue;
                    }
                }

                var winner = participants[RandomNumberGenerator.GetInt32(participants.Count)];

                giveaway.WinnerParticipantId = winner.Id;
                giveaway.IsClosed = true;

                try
                {
                    await _context.SaveChangesAsync();
                    await tx.CommitAsync();
                    return winner;
                }
                catch (DbUpdateConcurrencyException) when (attempt < maxRetries)
                {
                    await tx.RollbackAsync();
                    _context.ChangeTracker.Clear();
                    continue;
                }
            }
        }
    }
}
