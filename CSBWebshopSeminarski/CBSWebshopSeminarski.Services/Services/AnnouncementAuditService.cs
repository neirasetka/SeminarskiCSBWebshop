using CSBWebshopSeminarski.Core.Entities;
using CSBWebshopSeminarski.Database;
using Microsoft.Extensions.Logging;

namespace CBSWebshopSeminarski.Services.Services
{
    public class AnnouncementAuditService
    {
        private readonly CocoSunBagsWebshopDbContext _dbContext;
        private readonly ILogger<AnnouncementAuditService> _logger;

        public AnnouncementAuditService(CocoSunBagsWebshopDbContext dbContext, ILogger<AnnouncementAuditService> logger)
        {
            _dbContext = dbContext;
            _logger = logger;
        }

        public async Task SaveAsync(AnnouncementAudit audit, CancellationToken cancellationToken = default)
        {
            try
            {
                _dbContext.AnnouncementAudits.Add(audit);
                await _dbContext.SaveChangesAsync(cancellationToken);
            }
            catch (Exception ex)
            {
                _logger.LogWarning(ex, "Failed to persist AnnouncementAudit. Subject: {Subject}, Segment: {Segment}", audit.Subject, audit.Segment);
            }
        }
    }
}
