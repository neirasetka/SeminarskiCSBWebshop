using System;

namespace CBSWebshopSeminarski.Model.Requests
{
    public class SetShippingInfoRequest
    {
        public string CarrierCode { get; set; } = string.Empty;
        public string TrackingNumber { get; set; } = string.Empty;
        public DateTime? EstimatedDeliveryDate { get; set; }
    }
}