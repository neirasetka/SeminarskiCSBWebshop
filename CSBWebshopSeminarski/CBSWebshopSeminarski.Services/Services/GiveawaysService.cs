using CSBWebshopSeminarski.Core.Entities;
using CSBWebshopSeminarski.Database;
using Microsoft.EntityFrameworkCore;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

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
            if (endDate <= startDate)
            {
                throw new ArgumentException("EndDate must be after StartDate");
            }
            var giveaway = new Giveaways
            {
                Title = title,
                StartDate = startDate,
                EndDate = endDate,
                IsClosed = false
            };

            _context.Giveaways.Add(giveaway);
            await _context.SaveChangesAsync();

            return giveaway;
        }

        public async Task<Participants> RegisterParticipantAsync(int giveawayId, string name, string email)
        {
            var giveaway = await _context.Giveaways.FindAsync(giveawayId)
                           ?? throw new InvalidOperationException("Giveaway not found");
            var now = DateTime.UtcNow;
            if (now < giveaway.StartDate || now > giveaway.EndDate || giveaway.IsClosed)
            {
                throw new InvalidOperationException("Giveaway is not accepting entries");
            }
            var alreadyExists = await _context.Participants.AnyAsync(p => p.GiveawayId == giveawayId && p.Email == email);
            if (alreadyExists)
            {
                throw new InvalidOperationException("Participant with this email already registered for this giveaway");
            }

            var participant = new Participants
            {
                Name = name,
                Email = email,
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

            var random = new Random();
            int index = random.Next(participants.Count);
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
            using var tx = await _context.Database.BeginTransactionAsync();

            var giveaway = await _context.Giveaways
                .Include(g => g.Participants)
                .FirstOrDefaultAsync(g => g.Id == giveawayId)
                ?? throw new InvalidOperationException("Giveaway not found");

            if (giveaway.IsClosed)
            {
                // Already closed: return existing winner if any
                if (giveaway.WinnerParticipantId.HasValue)
                {
                    return await _context.Participants.FindAsync(giveaway.WinnerParticipantId.Value);
                }
                return null;
            }

            if (DateTime.UtcNow < giveaway.EndDate)
            {
                throw new InvalidOperationException("Giveaway has not ended yet");
            }

            var participants = giveaway.Participants.ToList();
            if (participants.Count == 0)
            {
                giveaway.IsClosed = true;
                await _context.SaveChangesAsync();
                await tx.CommitAsync();
                return null;
            }

            var random = new Random();
            var winner = participants[random.Next(participants.Count)];

            giveaway.WinnerParticipantId = winner.Id;
            giveaway.IsClosed = true;
            await _context.SaveChangesAsync();
            await tx.CommitAsync();

            return winner;
        }
    }
}
