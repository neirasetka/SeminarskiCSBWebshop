namespace CBSWebshopSeminarski.Model.Models
{
    public class TrackingEvent
    {
        public int TrackingEventID { get; set; }
        public int OrderID { get; set; }
        public ShippingStatus Status { get; set; }
        public string? Message { get; set; }
        public string? Location { get; set; }
        public DateTime OccurredAt { get; set; }
        public string? Source { get; set; }
        public string? ExternalStatus { get; set; }
    }
}
