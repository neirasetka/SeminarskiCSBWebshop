using CBSWebshopSeminarski.Model.DTOs;
using CBSWebshopSeminarski.Model.Models;
using CBSWebshopSeminarski.Model.Requests;
using CSBWebshopSeminarski.Core.Entities;

namespace CBSWebshopSeminarski.Services.Interfaces
{
    public interface IGiveawaysService
    {
        Task<PagedResult<GiveawayDto>> GetAllAsync(GiveawaySearchRequest search);
        Task<GiveawayDto?> GetByIdAsync(int id);
        Task<PagedResult<ParticipantDto>> GetParticipantsAsync(int giveawayId, PagedSearchRequest search);
        Task<Giveaways> CreateGiveawayAsync(string title, DateTime startDate, DateTime endDate);
        Task<Giveaways> UpdateGiveawayDurationAsync(int giveawayId, DateTime startDate, DateTime endDate);
        Task<Participants> RegisterParticipantAsync(int giveawayId, string name, string email);
        Task<Participants?> DrawAndPersistWinnerAsync(int giveawayId);
        Task NotifyWinnerAsync(Participants winner);
        Task<Participants> NotifyWinnerForGiveawayAsync(int giveawayId);
        Task<AnnounceWinnerResult> AnnounceWinnerAsync(int giveawayId, string? initiatedBy = null);
    }
}
