namespace CBSWebshopSeminarski.Model.DTOs
{
    public class NewsletterSubscriptionResult
    {
        public string Email { get; set; } = string.Empty;
        public bool IsSubscribedToGiveaway { get; set; }
        public bool IsSubscribedToNewCollections { get; set; }
    }

    public class NewsletterSubscriptionStatusResult
    {
        public string Email { get; set; } = string.Empty;
        public bool IsSubscribedToGiveaway { get; set; }
        public bool IsSubscribedToNewCollections { get; set; }
    }

    public class NewsletterSubscriberDto
    {
        public int Id { get; set; }
        public string Email { get; set; } = string.Empty;
        public bool IsSubscribedToGiveaway { get; set; }
        public bool IsSubscribedToNewCollections { get; set; }
    }
}
