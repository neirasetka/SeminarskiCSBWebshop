namespace CBSWebshopSeminarski.Services.Interfaces
{
    public interface IPaymentsService
    {
        Task HandlePaymentSucceededAsync(string paymentIntentId, IDictionary<string, string> metadata);
        Task HandlePaymentFailedAsync(string paymentIntentId, IDictionary<string, string> metadata, string failureMessage);

        /// <summary>
        /// Sends a payment confirmation email at most once per order (tracked on the order row).
        /// </summary>
        Task SendPaymentConfirmationIfNotSentYetAsync(int orderId, string? receiptEmailOverride);
    }
}
