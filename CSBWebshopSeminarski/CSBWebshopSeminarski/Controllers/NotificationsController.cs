using CBSWebshopSeminarski.Model.Models;
using CBSWebshopSeminarski.Services.Exceptions;
using CBSWebshopSeminarski.Services.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Security.Claims;

namespace CSBWebshopSeminarski.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    [Authorize]
    public class NotificationsController : ControllerBase
    {
        private readonly IInAppNotificationService _notificationService;

        public NotificationsController(IInAppNotificationService notificationService)
        {
            _notificationService = notificationService;
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
            if (userId == 0)
                throw new ForbiddenException("Access denied.");

            return Ok(await _notificationService.GetForUserAsync(userId, page, pageSize));
        }

        [HttpGet("unread-count")]
        public async Task<ActionResult<int>> GetUnreadCount()
        {
            var userId = GetCurrentUserId();
            if (userId == 0)
                throw new ForbiddenException("Access denied.");

            return Ok(await _notificationService.GetUnreadCountAsync(userId));
        }

        [HttpPatch("{id:int}/read")]
        public async Task<ActionResult> MarkAsRead(int id)
        {
            var userId = GetCurrentUserId();
            if (userId == 0)
                throw new ForbiddenException("Access denied.");

            var updated = await _notificationService.MarkAsReadAsync(userId, id);
            if (!updated)
                throw new NotFoundException("Notification not found.");

            return NoContent();
        }

        [HttpPatch("read-all")]
        public async Task<ActionResult> MarkAllAsRead()
        {
            var userId = GetCurrentUserId();
            if (userId == 0)
                throw new ForbiddenException("Access denied.");

            await _notificationService.MarkAllAsReadAsync(userId);
            return NoContent();
        }
    }
}
