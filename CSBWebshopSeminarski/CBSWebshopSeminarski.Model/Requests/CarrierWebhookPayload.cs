using System.ComponentModel.DataAnnotations;

namespace CBSWebshopSeminarski.Model.Requests
{
    public class CarrierWebhookPayload : IValidatableObject
    {
        [Range(1, int.MaxValue, ErrorMessage = "OrderID must be a positive integer when provided.")]
        public int? OrderID { get; set; }

        [MaxLength(100, ErrorMessage = "TrackingNumber can be up to 100 characters.")]
        public string? TrackingNumber { get; set; }

        [Required(ErrorMessage = "Status is required.")]
        [MaxLength(64, ErrorMessage = "Status can be up to 64 characters.")]
        public string? Status { get; set; }

        [MaxLength(500, ErrorMessage = "Message can be up to 500 characters.")]
        public string? Message { get; set; }

        [MaxLength(200, ErrorMessage = "Location can be up to 200 characters.")]
        public string? Location { get; set; }

        public DateTime? OccurredAt { get; set; }

        [MaxLength(10_000, ErrorMessage = "RawJson can be up to 10000 characters.")]
        public string? RawJson { get; set; }

        public IEnumerable<ValidationResult> Validate(ValidationContext validationContext)
        {
            var hasOrderId = OrderID is > 0;
            var hasTrackingNumber = !string.IsNullOrWhiteSpace(TrackingNumber);

            if (!hasOrderId && !hasTrackingNumber)
            {
                yield return new ValidationResult(
                    "Either OrderID or TrackingNumber must be provided.",
                    new[] { nameof(OrderID), nameof(TrackingNumber) });
            }
        }
    }
}
