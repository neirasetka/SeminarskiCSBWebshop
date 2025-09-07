using CBSWebshopSeminarski.Model.Requests;
using CBSWebshopSeminarski.Services.Interfaces;
using CBSWebshopSeminarski.Services.Services;
using CSBWebshopSeminarski.Core.Entities;
using CSBWebshopSeminarski.Database;
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
        private readonly NotificationsService _notificationService;
        private readonly ITemplateRenderer _templateRenderer;
        private readonly AnnouncementAuditService _auditService;
        private readonly ILogger<AnnouncementsController> _logger;
        private readonly CocoSunBagsWebshopDbContext _db;

        public AnnouncementsController(
            NotificationsService notificationService,
            ITemplateRenderer templateRenderer,
            AnnouncementAuditService auditService,
            ILogger<AnnouncementsController> logger,
            CocoSunBagsWebshopDbContext db)
        {
            _notificationService = notificationService;
            _templateRenderer = templateRenderer;
            _auditService = auditService;
            _logger = logger;
            _db = db;
        }

        [HttpPost("giveaway")]
        public async Task<IActionResult> AnnounceGiveaway([FromBody] AnnouncementRequest request)
        {
            var subject = string.IsNullOrWhiteSpace(request.Subject) ? "Exciting Giveaway Announcement!" : request.Subject!;
            var body = _templateRenderer.Render(request.TemplateKey ?? "giveaway-default", request.Body, request.Variables);

            int sent = 0;
            string? error = null;
            try
            {
                sent = await _notificationService.NotifySubscribersAboutGiveaway(subject, body);
            }
            catch (Exception ex)
            {
                error = ex.Message;
                _logger.LogError(ex, "Failed to send giveaway announcement");
            }

            await _auditService.SaveAsync(new CSBWebshopSeminarski.Core.Entities.AnnouncementAudit
            {
                SentAtUtc = DateTime.UtcNow,
                InitiatedBy = User?.Identity?.Name,
                Subject = subject,
                TemplateKey = request.TemplateKey ?? "giveaway-default",
                Segment = AnnouncementSegment.GiveawaySubscribers.ToString(),
                RecipientsCount = sent,
                IsSuccess = error == null,
                ErrorMessage = error
            });

            if (error != null)
            {
                return Problem(detail: error, statusCode: 500);
            }

            await PersistNewsAsync(subject, body, request, AnnouncementSegment.GiveawaySubscribers);
            return Ok(new { sent });
        }

        [HttpPost("new-collection")]
        public async Task<IActionResult> AnnounceNewCollection([FromBody] AnnouncementRequest request)
        {
            var subject = string.IsNullOrWhiteSpace(request.Subject) ? "Check Out Our New Collection!" : request.Subject!;
            var body = _templateRenderer.Render(request.TemplateKey ?? "new-collection-default", request.Body, request.Variables);

            int sent = 0;
            string? error = null;
            try
            {
                sent = await _notificationService.NotifySubscribersAboutNewCollection(subject, body);
            }
            catch (Exception ex)
            {
                error = ex.Message;
                _logger.LogError(ex, "Failed to send new collection announcement");
            }

            await _auditService.SaveAsync(new CSBWebshopSeminarski.Core.Entities.AnnouncementAudit
            {
                SentAtUtc = DateTime.UtcNow,
                InitiatedBy = User?.Identity?.Name,
                Subject = subject,
                TemplateKey = request.TemplateKey ?? "new-collection-default",
                Segment = AnnouncementSegment.NewCollectionSubscribers.ToString(),
                RecipientsCount = sent,
                IsSuccess = error == null,
                ErrorMessage = error
            });

            if (error != null)
            {
                return Problem(detail: error, statusCode: 500);
            }

            await PersistNewsAsync(subject, body, request, AnnouncementSegment.NewCollectionSubscribers);
            return Ok(new { sent });
        }

        private async Task PersistNewsAsync(string subject, string body, AnnouncementRequest request, AnnouncementSegment segment)
        {
            var item = new NewsItem
            {
                PublishedAtUtc = DateTime.UtcNow,
                Title = subject,
                Body = body,
                Segment = segment.ToString(),
                LaunchDate = request.LaunchDate,
                ProductName = request.ProductName,
                Price = request.Price,
                Color = request.Color,
                CreatedBy = User?.Identity?.Name
            };
            _db.News.Add(item);
            await _db.SaveChangesAsync();
        }
    }
}
