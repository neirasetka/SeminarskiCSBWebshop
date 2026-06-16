using System.ComponentModel.DataAnnotations;
using CBSWebshopSeminarski.Model;

namespace CBSWebshopSeminarski.Model.Requests
{
    public class ReviewUpsertRequest : IValidatableObject
    {
        /// <summary>Set by server from JWT; ignored if sent by client.</summary>
        public int UserID { get; set; }

        public int? BagID { get; set; }
        public int? BeltID { get; set; }

        [Required(ErrorMessage = "Comment is required.")]
        [MinLength(3, ErrorMessage = "Comment must be at least 3 characters long.")]
        [MaxLength(1000, ErrorMessage = "A comment can have a maximum of 1000 characters.")]
        public string Comment { get; set; } = null!;

        /// <summary>Opcionalno u POST-u — server postavlja UTC sada ako nije poslano.</summary>
        public DateTime Date { get; set; }

        public IEnumerable<ValidationResult> Validate(ValidationContext validationContext)
        {
            foreach (var result in BagOrBeltReferenceValidation.ValidateExactlyOne(BagID, BeltID, "Review"))
            {
                yield return result;
            }
        }
    }
}
