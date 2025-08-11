namespace CBSWebshopSeminarski.Model.Requests
{
    public enum AnnouncementSegment
    {
        GiveawaySubscribers,
        NewCollectionSubscribers,
        AllSubscribers
    }

    public class AnnouncementRequest
    {
        public string? Subject { get; set; }
        public string? Body { get; set; }
        public string? TemplateKey { get; set; }
        public Dictionary<string, string>? Variables { get; set; }
        public AnnouncementSegment Segment { get; set; } = AnnouncementSegment.AllSubscribers;

        // Optional structured fields to be persisted into NewsItem for infopanel
        public DateTime? LaunchDate { get; set; }
        public string? ProductName { get; set; }
        public decimal? Price { get; set; }
        public string? Color { get; set; }
    }
}