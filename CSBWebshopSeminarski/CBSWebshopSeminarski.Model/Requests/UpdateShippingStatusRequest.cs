using System.ComponentModel.DataAnnotations;
using CBSWebshopSeminarski.Model.Models;

namespace CBSWebshopSeminarski.Model.Requests
{
    public class UpdateShippingStatusRequest
    {
        [Required(ErrorMessage = "Status is required.")]
        public ShippingStatus Status { get; set; }

        [MaxLength(500, ErrorMessage = "Message can have a maximum of 500 characters.")]
        public string? Message { get; set; }

        [MaxLength(200, ErrorMessage = "Location can have a maximum of 200 characters.")]
        public string? Location { get; set; }

        public DateTime? OccurredAt { get; set; }
    }
}
