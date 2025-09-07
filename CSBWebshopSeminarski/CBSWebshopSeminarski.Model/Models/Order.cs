namespace CBSWebshopSeminarski.Model.Models
{
    public class Order
    {
        public int OrderID { get; set; }
        public string OrderNumber { get; set; }
        public DateTime Date { get; set; }
        public int UserID { get; set; }
        public decimal Amount { get; set; }
        public string UserUserName { get; set; }
        public ICollection<OrderItem> OrderItems { get; set; }
        public string? TrackingNumber { get; set; }
        public string? CarrierCode { get; set; }
        public ShippingStatus ShippingStatus { get; set; }
        public DateTime? LastStatusUpdate { get; set; }
        public DateTime? EstimatedDeliveryDate { get; set; }
        public string? PaymentStatus { get; set; }
    }
}
