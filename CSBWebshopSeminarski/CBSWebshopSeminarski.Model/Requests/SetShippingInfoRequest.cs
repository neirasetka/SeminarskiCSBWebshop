using System.ComponentModel.DataAnnotations;
using CBSWebshopSeminarski.Model;

namespace CBSWebshopSeminarski.Model.Requests
{
    public class SetShippingInfoRequest
    {
        [MaxLength(50, ErrorMessage = ValidationMessages.CarrierCodeMaxLength)]
        public string CarrierCode { get; set; } = string.Empty;

        [Required(ErrorMessage = ValidationMessages.TrackingNumberRequired)]
        [MinLength(3, ErrorMessage = ValidationMessages.TrackingNumberMinLength)]
        [MaxLength(100, ErrorMessage = ValidationMessages.TrackingNumberMaxLength)]
        public string TrackingNumber { get; set; } = string.Empty;

        public DateTime? EstimatedDeliveryDate { get; set; }
    }
}
