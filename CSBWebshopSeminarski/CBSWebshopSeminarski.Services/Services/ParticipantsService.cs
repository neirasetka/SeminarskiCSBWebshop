using CSBWebshopSeminarski.Core.Entities;
using CSBWebshopSeminarski.Database;
using Microsoft.EntityFrameworkCore;
using CBSWebshopSeminarski.Services.Interfaces;

namespace CBSWebshopSeminarski.Services.Services
{
    public class ParticipantsService : IParticipantsService
    {
        private readonly CocoSunBagsWebshopDbContext _context;
        public ParticipantsService(CocoSunBagsWebshopDbContext context)
        {
            _context = context;
        }

        public async Task<Participants> AddAsync(Participants participant)
        {
            _context.Participants.Add(participant);
            await _context.SaveChangesAsync();
            return participant;
        }

        public async Task<Participants?> GetRandomWinnerAsync()
        {
            // Kept for backward compatibility; not meaningful without giveaway context
            var participants = await _context.Participants.ToListAsync();
            if (participants.Count == 0) return null;
            var random = new Random();
            return participants[random.Next(participants.Count)];
        }

        public async Task<Participants?> GetRandomWinnerAsync(int giveawayId)
        {
            var participants = await _context.Participants
                .Where(p => p.GiveawayId == giveawayId)
                .ToListAsync();
            if (participants.Count == 0) return null;
            var random = new Random();
            return participants[random.Next(participants.Count)];
        }
    }
}
