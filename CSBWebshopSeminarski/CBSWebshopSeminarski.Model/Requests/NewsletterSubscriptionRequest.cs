using System.ComponentModel.DataAnnotations;

namespace CBSWebshopSeminarski.Model.Requests
{
    public class NewsletterSubscriptionRequest
    {
        [Required]
        [EmailAddress]
        public string Email { get; set; } = string.Empty;

        public bool? IsSubscribedToGiveaway { get; set; }
        public bool? IsSubscribedToNewCollections { get; set; }
    }
}
