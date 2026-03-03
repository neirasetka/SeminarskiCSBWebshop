namespace CBSWebshopSeminarski.Model.Models
{
    public class Order
    {
        public int OrderID { get; set; }
        public string OrderNumber { get; set; } = null!;
        public DateTime Date { get; set; }
        public int UserID { get; set; }
        public decimal Amount { get; set; }
        public string UserUserName { get; set; } = null!;
        public ICollection<OrderItem> OrderItems { get; set; } = null!;
        public string? TrackingNumber { get; set; }
        public string? CarrierCode { get; set; }
        public ShippingStatus ShippingStatus { get; set; }
        public DateTime? LastStatusUpdate { get; set; }
        public DateTime? EstimatedDeliveryDate { get; set; }
        public string? PaymentStatus { get; set; }
    }
}
