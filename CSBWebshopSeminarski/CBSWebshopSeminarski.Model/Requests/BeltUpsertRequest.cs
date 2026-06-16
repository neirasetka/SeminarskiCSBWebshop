using System.ComponentModel.DataAnnotations;

namespace CBSWebshopSeminarski.Model.Requests
{
    public class BeltUpsertRequest : IValidatableObject
    {
        [Required(ErrorMessage = "Belt name is required.")]
        [MinLength(2, ErrorMessage = "Belt name must have at least 2 characters.")]
        [MaxLength(200, ErrorMessage = "Belt name can be up to 200 characters.")]
        public string BeltName { get; set; } = null!;

        [Required(ErrorMessage = "Product code is required.")]
        [MaxLength(50, ErrorMessage = "Product code can be up to 50 characters.")]
        public string Code { get; set; } = null!;

        [Required(ErrorMessage = "Price is required.")]
        [Range(typeof(decimal), "0.01", "100000000", ErrorMessage = "Price must be greater than zero.")]
        public decimal Price { get; set; }

        [MaxLength(2000, ErrorMessage = "Description can be up to 2000 characters.")]
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
                    "Belt type is required.",
                    new[] { nameof(BeltTypeID) });
            }

            // UserID may be 0 from client; BeltsController fills it from JWT before Insert.
        }
    }
}
