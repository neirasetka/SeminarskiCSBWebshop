using CBSWebshopSeminarski.Model.Requests;

namespace CBSWebshopSeminarski.Services.Interfaces
{
    public interface IPaymentsService
    {
        StripeConfigResponse GetStripeConfig();

        Task<CreatePaymentIntentResponse> CreatePaymentIntentAsync(
            CreatePaymentIntentRequest request,
            int? currentUserId,
            bool isAdmin);

        Task<CreateCheckoutSessionResponse> CreateCheckoutSessionAsync(
            CreateCheckoutSessionRequest request,
            int? currentUserId,
            bool isAdmin,
            CheckoutRedirectContext redirectContext);

        Task<PaymentConfirmResult> ConfirmCheckoutSessionAsync(
            string sessionId,
            int? orderId,
            int? currentUserId,
            bool isAdmin);

        Task<PaymentConfirmResult> ConfirmPaymentIntentAsync(
            string paymentIntentId,
            int? orderId,
            int? currentUserId,
            bool isAdmin);

        Task<PaymentConfirmResult> ReconcileOrderPaymentAsync(int orderId);

        Task HandlePaymentSucceededAsync(string paymentIntentId, IDictionary<string, string> metadata);

        Task HandlePaymentFailedAsync(string paymentIntentId, IDictionary<string, string> metadata, string failureMessage);

        Task SendPaymentConfirmationIfNotSentYetAsync(int orderId, string? receiptEmailOverride);
    }
}
