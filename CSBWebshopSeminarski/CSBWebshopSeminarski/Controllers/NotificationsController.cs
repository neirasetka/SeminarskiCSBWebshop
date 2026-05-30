using CBSWebshopSeminarski.Model;
using CBSWebshopSeminarski.Model.Models;
using CBSWebshopSeminarski.Model.Requests;
using CSBWebshopSeminarski.Database;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System.Security.Claims;

namespace CSBWebshopSeminarski.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    [Authorize]
    public class NotificationsController : ControllerBase
    {
        private readonly CocoSunBagsWebshopDbContext _db;

        public NotificationsController(CocoSunBagsWebshopDbContext db)
        {
            _db = db;
        }

        private int GetCurrentUserId()
        {
            var claim = User.FindFirstValue(ClaimTypes.NameIdentifier);
            return int.TryParse(claim, out var id) ? id : 0;
        }

        [HttpGet]
        public async Task<ActionResult<PagedResult<Notification>>> GetMyNotifications([FromQuery] int page = 1, [FromQuery] int pageSize = 20)
        {
            var userId = GetCurrentUserId();
            if (userId == 0) return Unauthorized();

            var (normalizedPage, normalizedPageSize) = PaginationHelper.Normalize(new PagedSearchRequest
            {
                Page = page,
                PageSize = pageSize
            });

            var query = _db.Notifications.Where(n => n.UserID == userId).OrderByDescending(n => n.CreatedAt);
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

            return Ok(new PagedResult<Notification>
            {
                Items = notifications,
                TotalCount = totalCount,
                Page = normalizedPage,
                PageSize = normalizedPageSize
            });
        }

        [HttpGet("unread-count")]
        public async Task<ActionResult<int>> GetUnreadCount()
        {
            var userId = GetCurrentUserId();
            if (userId == 0) return Unauthorized();
            var count = await _db.Notifications.CountAsync(n => n.UserID == userId && !n.IsRead);
            return Ok(count);
        }

        [HttpPatch("{id:int}/read")]
        public async Task<ActionResult> MarkAsRead(int id)
        {
            var userId = GetCurrentUserId();
            if (userId == 0) return Unauthorized();

            var notification = await _db.Notifications.FirstOrDefaultAsync(n => n.NotificationID == id && n.UserID == userId);
            if (notification == null) return NotFound();

            notification.IsRead = true;
            await _db.SaveChangesAsync();
            return NoContent();
        }

        [HttpPatch("read-all")]
        public async Task<ActionResult> MarkAllAsRead()
        {
            var userId = GetCurrentUserId();
            if (userId == 0) return Unauthorized();

            var unread = await _db.Notifications
                .Where(n => n.UserID == userId && !n.IsRead)
                .ToListAsync();

            foreach (var n in unread)
                n.IsRead = true;

            await _db.SaveChangesAsync();
            return NoContent();
        }
    }
}
