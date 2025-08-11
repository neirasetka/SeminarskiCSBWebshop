namespace CSBWebshopSeminarski.Core.Entities
{
    public class AnnouncementAudit
    {
        public int Id { get; set; }
        public DateTime SentAtUtc { get; set; }
        public string? InitiatedBy { get; set; }
        public string? Subject { get; set; }
        public string? TemplateKey { get; set; }
        public string? Segment { get; set; }
        public int RecipientsCount { get; set; }
        public bool IsSuccess { get; set; }
        public string? ErrorMessage { get; set; }
    }
}