using CBSWebshopSeminarski.Services.Services;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Authorization;

namespace CSBWebshopSeminarski.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    [Authorize(Roles = "Admin")]
    public class AnnouncementsController : ControllerBase
    {
        private readonly NotificationsService _notificationService;

        public AnnouncementsController(NotificationsService notificationService)
        {
            _notificationService = notificationService;
        }

        [HttpPost("giveaway")]
        public async Task<IActionResult> AnnounceGiveaway([FromBody] string message)
        {
            string subject = "Exciting Giveaway Announcement!";
            await _notificationService.NotifySubscribersAboutGiveaway(subject, message);
            return Ok();
        }

        [HttpPost("new-collection")]
        public async Task<IActionResult> AnnounceNewCollection([FromBody] string message)
        {
            string subject = "Check Out Our New Collection!";
            await _notificationService.NotifySubscribersAboutNewCollection(subject, message);
            return Ok();
        }
    }
}
