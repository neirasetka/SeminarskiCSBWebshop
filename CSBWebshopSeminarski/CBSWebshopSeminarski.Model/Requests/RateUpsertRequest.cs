using System.ComponentModel.DataAnnotations;
using CBSWebshopSeminarski.Model;

namespace CBSWebshopSeminarski.Model.Requests
{
    public class RateUpsertRequest : IValidatableObject
    {
        /// <summary>Set by server from JWT; ignored if sent by client.</summary>
        public int UserID { get; set; }
        
        public int? BagID { get; set; }
        public int? BeltID { get; set; }
        
        [Required(ErrorMessage = "Rating is required.")]
        [Range(1, 5, ErrorMessage = "Rating must be between 1 and 5.")]
        public int Rating { get; set; }

        public IEnumerable<ValidationResult> Validate(ValidationContext validationContext)
        {
            foreach (var result in BagOrBeltReferenceValidation.ValidateExactlyOne(BagID, BeltID, "Rate"))
            {
                yield return result;
            }
        }
    }
}
