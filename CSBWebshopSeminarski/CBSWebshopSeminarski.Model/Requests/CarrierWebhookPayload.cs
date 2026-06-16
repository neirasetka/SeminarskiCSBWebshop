using System.ComponentModel.DataAnnotations;
using CBSWebshopSeminarski.Model;

namespace CBSWebshopSeminarski.Model.Requests
{
    public class CarrierWebhookPayload : IValidatableObject
    {
        [Range(1, int.MaxValue, ErrorMessage = ValidationMessages.OrderIdPositiveWhenProvided)]
        public int? OrderID { get; set; }

        [MaxLength(100, ErrorMessage = ValidationMessages.TrackingNumberMaxLength)]
        public string? TrackingNumber { get; set; }

        [Required(ErrorMessage = ValidationMessages.StatusRequired)]
        [MaxLength(64, ErrorMessage = ValidationMessages.StatusMaxLength64)]
        public string? Status { get; set; }

        [MaxLength(500, ErrorMessage = ValidationMessages.MessageMaxLength)]
        public string? Message { get; set; }

        [MaxLength(200, ErrorMessage = ValidationMessages.LocationMaxLength)]
        public string? Location { get; set; }

        public DateTime? OccurredAt { get; set; }

        [MaxLength(10_000, ErrorMessage = ValidationMessages.RawJsonMaxLength)]
        public string? RawJson { get; set; }

        public IEnumerable<ValidationResult> Validate(ValidationContext validationContext)
        {
            var hasOrderId = OrderID is > 0;
            var hasTrackingNumber = !string.IsNullOrWhiteSpace(TrackingNumber);

            if (!hasOrderId && !hasTrackingNumber)
            {
                yield return new ValidationResult(
                    "Potrebno je navesti OrderID ili TrackingNumber.",
                    new[] { nameof(OrderID), nameof(TrackingNumber) });
            }
        }
    }
}
