using CBSWebshopSeminarski.Model.DTOs;
using CBSWebshopSeminarski.Model.Requests;

namespace CBSWebshopSeminarski.Services.Interfaces
{
    public interface INewsletterService
    {
        Task<NewsletterSubscriptionResult> SubscribeAsync(NewsletterSubscriptionRequest request);
        Task<NewsletterSubscriptionStatusResult> GetSubscriptionStatusAsync(string email);
        Task<IReadOnlyList<NewsletterSubscriberDto>> GetSubscribersAsync();
    }
}
