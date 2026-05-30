using CBSWebshopSeminarski.Model.DTOs;
using CBSWebshopSeminarski.Model.Models;
using CBSWebshopSeminarski.Model.Requests;

namespace CBSWebshopSeminarski.Services.Interfaces
{
    public interface INewsletterService
    {
        Task<NewsletterSubscriptionResult> SubscribeAsync(NewsletterSubscriptionRequest request);
        Task<NewsletterSubscriptionStatusResult> GetSubscriptionStatusAsync(string email);
        Task<PagedResult<NewsletterSubscriberDto>> GetSubscribersAsync(PagedSearchRequest search);
    }
}
