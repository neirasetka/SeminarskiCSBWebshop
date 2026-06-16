using System.ComponentModel.DataAnnotations;
using CBSWebshopSeminarski.Model;

namespace CBSWebshopSeminarski.Model.Requests
{
    public class FavoriteUpsertRequest : IValidatableObject
    {
        [Required(ErrorMessage = ValidationMessages.UserIdRequired)]
        [Range(1, int.MaxValue, ErrorMessage = ValidationMessages.UserIdValid)]
        public int UserID { get; set; }

        public int? BagID { get; set; }
        public int? BeltID { get; set; }

        public IEnumerable<ValidationResult> Validate(ValidationContext validationContext)
        {
            foreach (var result in BagOrBeltReferenceValidation.ValidateExactlyOne(BagID, BeltID, "Favorit"))
            {
                yield return result;
            }
        }
    }
}
