using CBSWebshopSeminarski.Model.Models;
using CBSWebshopSeminarski.Model.Requests;
using CBSWebshopSeminarski.Services;
using CBSWebshopSeminarski.Services.Interfaces;
using CSBWebshopSeminarski.Core.Entities;
using CSBWebshopSeminarski.Database;
using Microsoft.Extensions.Logging;

namespace CBSWebshopSeminarski.Services.Services
{
    public class AnnouncementsService : IAnnouncementsService
    {
        private readonly CocoSunBagsWebshopDbContext _context;
        private readonly NotificationsService _notificationService;
        private readonly ITemplateRenderer _templateRenderer;
        private readonly ILogger<AnnouncementsService> _logger;

        public AnnouncementsService(
            CocoSunBagsWebshopDbContext context,
            NotificationsService notificationService,
            ITemplateRenderer templateRenderer,
            ILogger<AnnouncementsService> logger)
        {
            _context = context;
            _notificationService = notificationService;
            _templateRenderer = templateRenderer;
            _logger = logger;
        }

        public Task<AnnouncementDispatchResult> AnnounceGiveawayAsync(
            AnnouncementRequest request,
            string? initiatedBy) =>
            DispatchAsync(
                request,
                initiatedBy,
                defaultSubject: "Exciting Giveaway Announcement!",
                defaultTemplateKey: "giveaway-default",
                AnnouncementSegment.GiveawaySubscribers,
                _notificationService.NotifySubscribersAboutGiveaway);

        public Task<AnnouncementDispatchResult> AnnounceNewCollectionAsync(
            AnnouncementRequest request,
            string? initiatedBy)
        {
            var subject = string.IsNullOrWhiteSpace(request.Subject)
                ? "Check Out Our New Collection!"
                : request.Subject!.Trim();
            var templateKey = string.IsNullOrWhiteSpace(request.TemplateKey) ? null : request.TemplateKey;
            var body = !string.IsNullOrWhiteSpace(request.Body) && templateKey == null
                ? request.Body!
                : _templateRenderer.Render(
                    templateKey ?? "new-collection-default",
                    request.Body,
                    request.Variables);

            return PersistAnnouncementAsync(
                request,
                initiatedBy,
                subject,
                body,
                templateKey ?? "custom-body",
                AnnouncementSegment.NewCollectionSubscribers,
                _notificationService.NotifySubscribersAboutNewCollection);
        }

        private async Task<AnnouncementDispatchResult> DispatchAsync(
            AnnouncementRequest request,
            string? initiatedBy,
            string defaultSubject,
            string defaultTemplateKey,
            AnnouncementSegment segment,
            Func<string, string, Task<int>> notifyAsync,
            bool useCustomBodyWhenNoTemplate = false)
        {
            var subject = string.IsNullOrWhiteSpace(request.Subject) ? defaultSubject : request.Subject!.Trim();
            var templateKey = string.IsNullOrWhiteSpace(request.TemplateKey) ? defaultTemplateKey : request.TemplateKey!;
            var body = useCustomBodyWhenNoTemplate
                       && !string.IsNullOrWhiteSpace(request.Body)
                       && string.IsNullOrWhiteSpace(request.TemplateKey)
                ? request.Body!
                : _templateRenderer.Render(templateKey, request.Body, request.Variables);

            return await PersistAnnouncementAsync(
                request,
                initiatedBy,
                subject,
                body,
                templateKey,
                segment,
                notifyAsync);
        }

        private async Task<AnnouncementDispatchResult> PersistAnnouncementAsync(
            AnnouncementRequest request,
            string? initiatedBy,
            string subject,
            string body,
            string templateKey,
            AnnouncementSegment segment,
            Func<string, string, Task<int>> notifyAsync)
        {
            var sent = 0;
            string? emailWarning = null;
            try
            {
                sent = await notifyAsync(subject, body);
            }
            catch (Exception ex)
            {
                emailWarning = ex.Message;
                _logger.LogError(ex, "Failed to send announcement emails for segment {Segment}", segment);
            }

            await _context.ExecuteInTransactionAsync(async () =>
            {
                _context.AnnouncementAudits.Add(new AnnouncementAudit
                {
                    SentAtUtc = DateTime.UtcNow,
                    InitiatedBy = initiatedBy,
                    Subject = subject,
                    TemplateKey = templateKey,
                    Segment = segment.ToString(),
                    RecipientsCount = sent,
                    IsSuccess = emailWarning == null,
                    ErrorMessage = emailWarning
                });

                _context.News.Add(new NewsItem
                {
                    PublishedAtUtc = DateTime.UtcNow,
                    Title = subject,
                    Body = body,
                    Segment = segment.ToString(),
                    LaunchDate = request.LaunchDate,
                    ProductName = request.ProductName,
                    Price = request.Price,
                    Color = request.Color,
                    CreatedBy = initiatedBy
                });

                await _context.SaveChangesAsync();
            });

            return new AnnouncementDispatchResult
            {
                Sent = sent,
                EmailWarning = emailWarning
            };
        }
    }
}
