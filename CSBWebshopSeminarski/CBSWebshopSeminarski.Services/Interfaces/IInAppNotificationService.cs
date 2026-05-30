using CBSWebshopSeminarski.Model.Models;
using CBSWebshopSeminarski.Model.Requests;

namespace CBSWebshopSeminarski.Services.Interfaces
{
    public interface IInAppNotificationService
    {
        Task CreateAsync(
            int userId,
            string type,
            string title,
            string message,
            int? relatedEntityId = null);

        Task<PagedResult<Notification>> GetForUserAsync(int userId, int page, int pageSize);

        Task<int> GetUnreadCountAsync(int userId);

        Task<bool> MarkAsReadAsync(int userId, int notificationId);

        Task MarkAllAsReadAsync(int userId);
    }
}
