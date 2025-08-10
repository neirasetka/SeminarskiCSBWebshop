using CSBWebshopSeminarski.Core.Entities;

namespace CBSWebshopSeminarski.Services.Interfaces
{
    public interface IParticipantsService
    {
        Task<Participants> AddAsync(Participants participant);
        Task<Participants?> GetRandomWinnerAsync();
        Task<Participants?> GetRandomWinnerAsync(int giveawayId);
    }
}
