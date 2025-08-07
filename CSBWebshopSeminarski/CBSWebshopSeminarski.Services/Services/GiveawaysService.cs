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

        public GiveawaysService(CocoSunBagsWebshopDbContext context)
        {
            _context = context;
        }

        public async Task<Giveaways> CreateGiveawayAsync(string title, DateTime startDate, DateTime endDate)
        {
            var giveaway = new Giveaways
            {
                Title = title,
                StartDate = startDate,
                EndDate = endDate
            };

            _context.Giveaways.Add(giveaway);
            await _context.SaveChangesAsync();

            return giveaway;
        }

        public async Task<Participants> RegisterParticipantAsync(int giveawayId, string name, string email)
        {
            var participant = new Participants
            {
                Name = name,
                Email = email,
                Id = giveawayId,
                EntryDate = DateTime.UtcNow
            };

            _context.Participants.Add(participant);
            await _context.SaveChangesAsync();

            return participant;
        }

        public async Task<Participants> SelectRandomWinnerAsync(int giveawayId)
        {
            var participants = await _context.Participants
                                             .Where(p => p.Id == giveawayId)
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
            //var emailService = new EmailService();
            //await emailService.SendEmailAsync(winner.Email, "Congratulations, You Are a Winner!", "You have won the giveaway!");
        }

        public async Task RunGiveawayAsync(int giveawayId)
        {
            // Nakon završetka giveaway-a, biramo pobednika
            var winner = await SelectRandomWinnerAsync(giveawayId);

            if (winner != null)
            {
                await NotifyWinnerAsync(winner);
            }
        }
    }
}
