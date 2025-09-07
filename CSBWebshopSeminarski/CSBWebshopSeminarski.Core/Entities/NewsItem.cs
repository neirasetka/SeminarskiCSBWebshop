namespace CSBWebshopSeminarski.Core.Entities
{
    public class NewsItem
    {
        public int Id { get; set; }
        public DateTime PublishedAtUtc { get; set; }
        public string Title { get; set; } = string.Empty;
        public string Body { get; set; } = string.Empty;
        public string Segment { get; set; } = string.Empty; //GiveawaySubscribers, NewCollectionSubscribers, AllSubscribers
        public DateTime? LaunchDate { get; set; }
        public string? ProductName { get; set; }
        public decimal? Price { get; set; }
        public string? Color { get; set; }
        public string? CreatedBy { get; set; }
    }
}
