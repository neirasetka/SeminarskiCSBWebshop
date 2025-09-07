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
        public string OrderNumber { get; set; }
        public DateTime Date { get; set; }
        public float Price { get; set; }
        public int UserID { get; set; }
        public Users User { get; set; }
        public ICollection<OrderItems> OrderItems { get; set; }

        // Payment
        public PaymentStatus PaymentStatus { get; set; } = PaymentStatus.Pending;
 
        // Shipping / tracking
        public string? TrackingNumber { get; set; }
        public string? CarrierCode { get; set; }
        public ShippingStatus ShippingStatus { get; set; } = ShippingStatus.Pending;
        public DateTime? LastStatusUpdate { get; set; }
        public DateTime? EstimatedDeliveryDate { get; set; }
        public ICollection<TrackingEvents> TrackingEvents { get; set; }
    }
}
