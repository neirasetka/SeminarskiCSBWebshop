using CBSWebshopSeminarski.Model.Requests;
using CBSWebshopSeminarski.Services.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.RateLimiting;

namespace CSBWebshopSeminarski.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    [Authorize(Roles = "Admin")]
    [EnableRateLimiting("AnnouncementsPolicy")]
    public class AnnouncementsController : ControllerBase
    {
        private readonly IAnnouncementsService _announcementsService;

        public AnnouncementsController(IAnnouncementsService announcementsService)
        {
            _announcementsService = announcementsService;
        }

        [HttpPost("giveaway")]
        public async Task<IActionResult> AnnounceGiveaway([FromBody] AnnouncementRequest request)
        {
            var result = await _announcementsService.AnnounceGiveawayAsync(
                request,
                User?.Identity?.Name);
            return Ok(new { sent = result.Sent, emailWarning = result.EmailWarning });
        }

        [HttpPost("new-collection")]
        public async Task<IActionResult> AnnounceNewCollection([FromBody] AnnouncementRequest request)
        {
            var result = await _announcementsService.AnnounceNewCollectionAsync(
                request,
                User?.Identity?.Name);
            return Ok(new { sent = result.Sent, emailWarning = result.EmailWarning });
        }
    }
}
