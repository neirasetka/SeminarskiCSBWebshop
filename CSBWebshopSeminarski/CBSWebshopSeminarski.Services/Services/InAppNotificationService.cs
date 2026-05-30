using CBSWebshopSeminarski.Model;
using CBSWebshopSeminarski.Model.Models;
using CBSWebshopSeminarski.Model.Requests;
using CBSWebshopSeminarski.Services.Interfaces;
using CSBWebshopSeminarski.Core.Entities;
using CSBWebshopSeminarski.Database;
using Microsoft.EntityFrameworkCore;

namespace CBSWebshopSeminarski.Services.Services;

public class InAppNotificationService : IInAppNotificationService
{
    private readonly CocoSunBagsWebshopDbContext _db;

    public InAppNotificationService(CocoSunBagsWebshopDbContext db)
    {
        _db = db;
    }

    public void StageCreate(
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
    }

    public async Task CreateAsync(
        int userId,
        string type,
        string title,
        string message,
        int? relatedEntityId = null)
    {
        StageCreate(userId, type, title, message, relatedEntityId);
        await _db.SaveChangesAsync();
    }

    public async Task<PagedResult<Notification>> GetForUserAsync(int userId, int page, int pageSize)
    {
        var (normalizedPage, normalizedPageSize) = PaginationHelper.Normalize(new PagedSearchRequest
        {
            Page = page,
            PageSize = pageSize
        });

        var query = _db.Notifications
            .AsNoTracking()
            .Where(n => n.UserID == userId)
            .OrderByDescending(n => n.CreatedAt);

        var totalCount = await query.CountAsync();
        var notifications = await query
            .Skip((normalizedPage - 1) * normalizedPageSize)
            .Take(normalizedPageSize)
            .Select(n => new Notification
            {
                NotificationID = n.NotificationID,
                UserID = n.UserID,
                Type = n.Type,
                Title = n.Title,
                Message = n.Message,
                RelatedEntityID = n.RelatedEntityID,
                IsRead = n.IsRead,
                CreatedAt = n.CreatedAt
            })
            .ToListAsync();

        return new PagedResult<Notification>
        {
            Items = notifications,
            TotalCount = totalCount,
            Page = normalizedPage,
            PageSize = normalizedPageSize
        };
    }

    public Task<int> GetUnreadCountAsync(int userId) =>
        _db.Notifications.CountAsync(n => n.UserID == userId && !n.IsRead);

    public async Task<bool> MarkAsReadAsync(int userId, int notificationId)
    {
        var notification = await _db.Notifications
            .FirstOrDefaultAsync(n => n.NotificationID == notificationId && n.UserID == userId);
        if (notification == null)
            return false;

        notification.IsRead = true;
        await _db.SaveChangesAsync();
        return true;
    }

    public async Task MarkAllAsReadAsync(int userId)
    {
        var unread = await _db.Notifications
            .Where(n => n.UserID == userId && !n.IsRead)
            .ToListAsync();

        foreach (var n in unread)
            n.IsRead = true;

        if (unread.Count > 0)
            await _db.SaveChangesAsync();
    }
}
