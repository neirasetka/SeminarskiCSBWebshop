namespace CBSWebshopSeminarski.Model.Models
{
    public class ShippingInfo
    {
        public int OrderID { get; set; }
        public string? OrderNumber { get; set; }
        public string? TrackingNumber { get; set; }
        public string? CarrierCode { get; set; }
        public ShippingStatus ShippingStatus { get; set; }
        public DateTime? LastStatusUpdate { get; set; }
        public DateTime? EstimatedDeliveryDate { get; set; }
        public List<TrackingEvent> TrackingEvents { get; set; } = new List<TrackingEvent>();
    }
}
