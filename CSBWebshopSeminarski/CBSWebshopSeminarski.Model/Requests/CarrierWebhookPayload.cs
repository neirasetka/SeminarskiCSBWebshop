using System;

namespace CBSWebshopSeminarski.Model.Requests
{
    public class CarrierWebhookPayload
    {
        public int? OrderID { get; set; }
        public string? TrackingNumber { get; set; }
        public string? Status { get; set; }
        public string? Message { get; set; }
        public string? Location { get; set; }
        public DateTime? OccurredAt { get; set; }
        public string? RawJson { get; set; }
    }
}