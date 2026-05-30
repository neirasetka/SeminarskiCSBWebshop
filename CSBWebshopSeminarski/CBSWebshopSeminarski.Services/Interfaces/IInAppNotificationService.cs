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
    }
}
