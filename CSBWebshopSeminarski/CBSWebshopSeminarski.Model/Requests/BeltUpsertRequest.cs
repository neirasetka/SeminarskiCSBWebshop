using System.ComponentModel.DataAnnotations;
using CBSWebshopSeminarski.Model;

namespace CBSWebshopSeminarski.Model.Requests
{
    public class BeltUpsertRequest : IValidatableObject
    {
        [Required(ErrorMessage = ValidationMessages.ProductNameRequired)]
        [MinLength(2, ErrorMessage = ValidationMessages.ProductNameMinLength)]
        [MaxLength(200, ErrorMessage = ValidationMessages.ProductNameMaxLength)]
        public string BeltName { get; set; } = null!;

        [Required(ErrorMessage = ValidationMessages.ProductCodeRequired)]
        [MaxLength(50, ErrorMessage = ValidationMessages.ProductCodeMaxLength)]
        public string Code { get; set; } = null!;

        [Required(ErrorMessage = ValidationMessages.PriceRequired)]
        [Range(typeof(decimal), "0.01", "100000000", ErrorMessage = ValidationMessages.PriceGreaterThanZero)]
        public decimal Price { get; set; }

        [MaxLength(2000, ErrorMessage = ValidationMessages.DescriptionMaxLength)]
        public string Description { get; set; } = null!;

        public int BeltTypeID { get; set; }

        /// <summary>Base64-encoded image data (e.g. from JSON).</summary>
        public string Image { get; set; } = null!;

        public int UserID { get; set; }

        public IEnumerable<ValidationResult> Validate(ValidationContext validationContext)
        {
            if (BeltTypeID <= 0)
            {
                yield return new ValidationResult(
                    "Odaberite tip kaiša",
                    new[] { nameof(BeltTypeID) });
            }

            // UserID may be 0 from client; BeltsController fills it from JWT before Insert.
        }
    }
}
