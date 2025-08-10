namespace CBSWebshopSeminarski.Services.Interfaces
{
    public interface IPaymentsService
    {
        Task HandlePaymentSucceededAsync(string paymentIntentId, IDictionary<string, string> metadata);
        Task HandlePaymentFailedAsync(string paymentIntentId, IDictionary<string, string> metadata, string failureMessage);
    }
}