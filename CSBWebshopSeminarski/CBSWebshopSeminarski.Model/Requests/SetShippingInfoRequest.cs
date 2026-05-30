using System.ComponentModel.DataAnnotations;

namespace CBSWebshopSeminarski.Model.Requests
{
    public class SetShippingInfoRequest
    {
        [MaxLength(50, ErrorMessage = "Carrier code can have a maximum of 50 characters.")]
        public string CarrierCode { get; set; } = string.Empty;

        [Required(ErrorMessage = "Tracking number is required.")]
        [MinLength(3, ErrorMessage = "Tracking number must be at least 3 characters.")]
        [MaxLength(100, ErrorMessage = "Tracking number can have a maximum of 100 characters.")]
        public string TrackingNumber { get; set; } = string.Empty;

        public DateTime? EstimatedDeliveryDate { get; set; }
    }
}
