using System.ComponentModel.DataAnnotations;
using CBSWebshopSeminarski.Model;

namespace CBSWebshopSeminarski.Model.Requests
{
    public class NewsletterSubscriptionRequest
    {
        [Required(ErrorMessage = ValidationMessages.EmailRequired)]
        [EmailAddress(ErrorMessage = ValidationMessages.EmailInvalid)]
        public string Email { get; set; } = string.Empty;

        public bool? IsSubscribedToGiveaway { get; set; }
        public bool? IsSubscribedToNewCollections { get; set; }
    }
}
