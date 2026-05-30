using System.ComponentModel.DataAnnotations;

namespace CBSWebshopSeminarski.Model.Requests
{
    public class ReportsSearchRequest : IValidatableObject
    {
        public DateTime? FromDateUtc { get; set; }
        public DateTime? ToDateUtc { get; set; }

        [Range(1, 10_000, ErrorMessage = "Take must be between 1 and 10000 when provided.")]
        public int? Take { get; set; }

        public IEnumerable<ValidationResult> Validate(ValidationContext validationContext)
        {
            if (FromDateUtc.HasValue && ToDateUtc.HasValue && ToDateUtc.Value < FromDateUtc.Value)
            {
                yield return new ValidationResult(
                    "ToDateUtc must be on or after FromDateUtc.",
                    new[] { nameof(ToDateUtc) });
            }
        }
    }
}
