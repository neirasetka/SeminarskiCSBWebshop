using System.ComponentModel.DataAnnotations;

namespace CSBWebshopSeminarski.Core.Entities
{
    public class Orders
    {
        public Orders()
        {
            OrderItems = new HashSet<OrderItems>();
            TrackingEvents = new HashSet<TrackingEvents>();
        }
        [Key]
        public int OrderID { get; set; }
        public string OrderNumber { get; set; } = null!;
        public DateTime Date { get; set; }
        public decimal Price { get; set; }
        public int UserID { get; set; }
        public Users User { get; set; } = null!;
        public ICollection<OrderItems> OrderItems { get; set; } = null!;

        // Payment
        public PaymentStatus PaymentStatus { get; set; } = PaymentStatus.Pending;

        /// <summary>
        /// Set when a payment confirmation email was sent successfully (idempotency for webhook + client PATCH).
        /// </summary>
        public bool PaymentConfirmationEmailSent { get; set; }

        /// <summary>Last Stripe PaymentIntent created for this order (used to block duplicate active payments).</summary>
        public string? StripePaymentIntentId { get; set; }

        /// <summary>Last Stripe Checkout Session created for this order (used to block duplicate active payments).</summary>
        public string? StripeCheckoutSessionId { get; set; }
 
        // Shipping/tracking
        public string? TrackingNumber { get; set; }
        public string? CarrierCode { get; set; }
        public ShippingStatus ShippingStatus { get; set; } = ShippingStatus.Pending;
        public DateTime? LastStatusUpdate { get; set; }
        public DateTime? EstimatedDeliveryDate { get; set; }
        public ICollection<TrackingEvents> TrackingEvents { get; set; } = null!;

        public DateTime? CancelledAt { get; set; }
        public int? CancelledByUserId { get; set; }
        public string? CancellationReason { get; set; }
        public virtual Users? CancelledByUser { get; set; }
    }
}
