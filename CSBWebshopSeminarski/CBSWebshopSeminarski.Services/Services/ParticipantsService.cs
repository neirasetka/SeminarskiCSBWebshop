using CBSWebshopSeminarski.Services.Interfaces;
using CSBWebshopSeminarski.Core.Entities;
using CSBWebshopSeminarski.Database;
using Microsoft.EntityFrameworkCore;
using System.Security.Cryptography;

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
            var participants = await _context.Participants.ToListAsync();
            if (participants.Count == 0) return null;
            var index = RandomNumberGenerator.GetInt32(participants.Count);
            return participants[index];
        }

        public async Task<Participants?> GetRandomWinnerAsync(int giveawayId)
        {
            var participants = await _context.Participants
                .Where(p => p.GiveawayId == giveawayId)
                .ToListAsync();
            if (participants.Count == 0) return null;
            var index = RandomNumberGenerator.GetInt32(participants.Count);
            return participants[index];
        }
    }
}
