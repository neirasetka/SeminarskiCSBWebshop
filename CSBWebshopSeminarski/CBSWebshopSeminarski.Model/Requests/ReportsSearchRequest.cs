using System.ComponentModel.DataAnnotations;
using CBSWebshopSeminarski.Model;

namespace CBSWebshopSeminarski.Model.Requests
{
    public class ReportsSearchRequest : IValidatableObject
    {
        public DateTime? FromDateUtc { get; set; }
        public DateTime? ToDateUtc { get; set; }

        [Range(1, 10_000, ErrorMessage = ValidationMessages.ReportsTakeRange)]
        public int? Take { get; set; }

        public IEnumerable<ValidationResult> Validate(ValidationContext validationContext)
        {
            if (FromDateUtc.HasValue && ToDateUtc.HasValue && ToDateUtc.Value < FromDateUtc.Value)
            {
                yield return new ValidationResult(
                    "ToDateUtc mora biti jednak ili nakon FromDateUtc.",
                    new[] { nameof(ToDateUtc) });
            }
        }
    }
}
