using CBSWebshopSeminarski.Model.Models;
using CBSWebshopSeminarski.Model.Requests;

namespace CBSWebshopSeminarski.Services.Interfaces
{
    public interface IAnnouncementsService
    {
        Task<AnnouncementDispatchResult> AnnounceGiveawayAsync(
            AnnouncementRequest request,
            string? initiatedBy);

        Task<AnnouncementDispatchResult> AnnounceNewCollectionAsync(
            AnnouncementRequest request,
            string? initiatedBy);
    }
}
