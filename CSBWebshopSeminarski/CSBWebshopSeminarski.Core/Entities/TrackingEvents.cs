using System;
using System.ComponentModel.DataAnnotations;

namespace CSBWebshopSeminarski.Core.Entities
{
    public class TrackingEvents
    {
        [Key]
        public int TrackingEventID { get; set; }
        public int OrderID { get; set; }
        public Orders Order { get; set; }

        public ShippingStatus Status { get; set; }
        public string? Message { get; set; }
        public string? Location { get; set; }
        public DateTime OccurredAt { get; set; }

        // Optional metadata
        public string? Source { get; set; } // Manual / Carrier / Webhook
        public string? ExternalStatus { get; set; }
        public string? RawPayload { get; set; }
    }
}