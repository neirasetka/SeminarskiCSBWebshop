using System.ComponentModel.DataAnnotations;
using CBSWebshopSeminarski.Model;
using CBSWebshopSeminarski.Model.Models;

namespace CBSWebshopSeminarski.Model.Requests
{
    public class UpdateShippingStatusRequest
    {
        [Required(ErrorMessage = ValidationMessages.StatusRequired)]
        public ShippingStatus Status { get; set; }

        [MaxLength(500, ErrorMessage = ValidationMessages.MessageMaxLength)]
        public string? Message { get; set; }

        [MaxLength(200, ErrorMessage = ValidationMessages.LocationMaxLength)]
        public string? Location { get; set; }

        public DateTime? OccurredAt { get; set; }
    }
}
