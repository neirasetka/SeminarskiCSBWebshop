using CBSWebshopSeminarski.Services.Interfaces;
using CSBWebshopSeminarski.Core.Entities;
using CSBWebshopSeminarski.Database;

namespace CBSWebshopSeminarski.Services.Services;

public class InAppNotificationService : IInAppNotificationService
{
    private readonly CocoSunBagsWebshopDbContext _db;

    public InAppNotificationService(CocoSunBagsWebshopDbContext db)
    {
        _db = db;
    }

    public async Task CreateAsync(
        int userId,
        string type,
        string title,
        string message,
        int? relatedEntityId = null)
    {
        if (userId <= 0)
            return;

        _db.Notifications.Add(new Notifications
        {
            UserID = userId,
            Type = type,
            Title = title,
            Message = message,
            RelatedEntityID = relatedEntityId,
            IsRead = false,
            CreatedAt = DateTime.UtcNow
        });

        await _db.SaveChangesAsync();
    }
}
