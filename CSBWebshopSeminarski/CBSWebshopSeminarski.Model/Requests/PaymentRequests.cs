using System.ComponentModel.DataAnnotations;
using CBSWebshopSeminarski.Model;

namespace CBSWebshopSeminarski.Model.Requests
{
    public class ConfirmCheckoutSessionRequest
    {
        [Required(ErrorMessage = ValidationMessages.SessionIdRequired)]
        [MinLength(1, ErrorMessage = ValidationMessages.SessionIdNotEmpty)]
        public string SessionId { get; set; } = string.Empty;

        [Range(1, int.MaxValue, ErrorMessage = ValidationMessages.OrderIdValidWhenProvided)]
        public int? OrderId { get; set; }
    }

    public class ConfirmPaymentIntentRequest
    {
        [Required(ErrorMessage = ValidationMessages.PaymentIntentIdRequired)]
        [MinLength(1, ErrorMessage = ValidationMessages.PaymentIntentIdNotEmpty)]
        public string PaymentIntentId { get; set; } = string.Empty;

        [Range(1, int.MaxValue, ErrorMessage = ValidationMessages.OrderIdValidWhenProvided)]
        public int? OrderId { get; set; }
    }

    public class PaymentConfirmResult
    {
        public bool Paid { get; set; }
        public int? OrderId { get; set; }
        public string? PaymentIntentId { get; set; }
        public string? Status { get; set; }
        public string? Reason { get; set; }
    }

    public class StripeConfigResponse
    {
        public string PublishableKey { get; set; } = string.Empty;
        public string Currency { get; set; } = "bam";
        public string CurrencyDisplay { get; set; } = "KM";
    }

    public class CheckoutRedirectContext
    {
        public string RequestScheme { get; set; } = string.Empty;
        public string RequestHost { get; set; } = string.Empty;
    }
}
