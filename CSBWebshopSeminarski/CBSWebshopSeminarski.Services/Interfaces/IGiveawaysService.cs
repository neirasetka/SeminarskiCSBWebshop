using CBSWebshopSeminarski.Model.DTOs;
using CSBWebshopSeminarski.Core.Entities;

namespace CBSWebshopSeminarski.Services.Interfaces
{
    public interface IGiveawaysService
    {
        Task<IReadOnlyList<GiveawayDto>> GetAllAsync(string? status);
        Task<GiveawayDto?> GetByIdAsync(int id);
        Task<IReadOnlyList<ParticipantDto>> GetParticipantsAsync(int giveawayId);
        Task<Giveaways> CreateGiveawayAsync(string title, DateTime startDate, DateTime endDate);
        Task<Giveaways> UpdateGiveawayDurationAsync(int giveawayId, DateTime startDate, DateTime endDate);
        Task<Participants> RegisterParticipantAsync(int giveawayId, string name, string email);
        Task<Participants?> DrawAndPersistWinnerAsync(int giveawayId);
        Task NotifyWinnerAsync(Participants winner);
        Task<Participants> NotifyWinnerForGiveawayAsync(int giveawayId);
        Task<AnnounceWinnerResult> AnnounceWinnerAsync(int giveawayId, string? initiatedBy = null);
    }
}
