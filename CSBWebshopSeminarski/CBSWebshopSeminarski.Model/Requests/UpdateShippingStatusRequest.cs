using CBSWebshopSeminarski.Model.Models;

namespace CBSWebshopSeminarski.Model.Requests
{
    public class UpdateShippingStatusRequest
    {
        public ShippingStatus Status { get; set; }
        public string? Message { get; set; }
        public string? Location { get; set; }
        public DateTime? OccurredAt { get; set; }
    }
}
