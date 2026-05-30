namespace CBSWebshopSeminarski.Services.Interfaces
{
    public interface IStripeWebhookService
    {
        Task ProcessWebhookAsync(string json, string signatureHeader);
    }
}
