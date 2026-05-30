using CBSWebshopSeminarski.Services.Interfaces;
using Microsoft.Extensions.Configuration;
using Stripe;

namespace CBSWebshopSeminarski.Services.Services
{
    public class StripeWebhookService : IStripeWebhookService
    {
        private readonly IPaymentsService _paymentsService;
        private readonly IConfiguration _configuration;

        public StripeWebhookService(
            IPaymentsService paymentsService,
            IConfiguration configuration)
        {
            _paymentsService = paymentsService;
            _configuration = configuration;
        }

        public async Task ProcessWebhookAsync(string json, string signatureHeader)
        {
            var stripeWebhookSecret = _configuration["Stripe:WebhookSecret"] ?? string.Empty;
            var stripeEvent = EventUtility.ConstructEvent(json, signatureHeader, stripeWebhookSecret);

            if (stripeEvent.Type == "payment_intent.succeeded")
            {
                var paymentIntent = (PaymentIntent)stripeEvent.Data.Object;
                var meta = paymentIntent.Metadata != null
                    ? new Dictionary<string, string>(paymentIntent.Metadata)
                    : new Dictionary<string, string>();

                if (!meta.TryGetValue("receipt_email", out var re) || string.IsNullOrWhiteSpace(re))
                {
                    if (!string.IsNullOrWhiteSpace(paymentIntent.ReceiptEmail))
                    {
                        meta["receipt_email"] = paymentIntent.ReceiptEmail;
                    }
                }

                await _paymentsService.HandlePaymentSucceededAsync(paymentIntent.Id, meta);
            }
            else if (stripeEvent.Type == "checkout.session.completed")
            {
                var session = (Stripe.Checkout.Session)stripeEvent.Data.Object;
                if (!string.IsNullOrEmpty(session.PaymentIntentId))
                {
                    var paymentIntentService = new PaymentIntentService();
                    var paymentIntent = await paymentIntentService.GetAsync(session.PaymentIntentId);
                    var meta = paymentIntent.Metadata != null
                        ? new Dictionary<string, string>(paymentIntent.Metadata)
                        : new Dictionary<string, string>();

                    if (!meta.TryGetValue("receipt_email", out var re) || string.IsNullOrWhiteSpace(re))
                    {
                        var fromSession = !string.IsNullOrWhiteSpace(session.CustomerEmail)
                            ? session.CustomerEmail
                            : session.CustomerDetails?.Email;
                        if (!string.IsNullOrWhiteSpace(fromSession))
                        {
                            meta["receipt_email"] = fromSession;
                        }
                    }

                    await _paymentsService.HandlePaymentSucceededAsync(paymentIntent.Id, meta);
                }
            }
            else if (stripeEvent.Type == "payment_intent.payment_failed")
            {
                var paymentIntent = (PaymentIntent)stripeEvent.Data.Object;
                await _paymentsService.HandlePaymentFailedAsync(
                    paymentIntent.Id,
                    paymentIntent.Metadata ?? new Dictionary<string, string>(),
                    paymentIntent.LastPaymentError?.Message ?? string.Empty);
            }
        }
    }
}
