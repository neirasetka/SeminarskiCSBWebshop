using System.ComponentModel.DataAnnotations;
using CBSWebshopSeminarski.Model;

namespace CBSWebshopSeminarski.Model.Requests
{
    public class OutfitIdeaUpsertRequest : IValidatableObject
    {
        public int? BagID { get; set; }

        public int? BeltID { get; set; }

        [Required(ErrorMessage = ValidationMessages.UserIdRequired)]
        [Range(1, int.MaxValue, ErrorMessage = ValidationMessages.UserIdValid)]
        public int UserID { get; set; }

        [Required(ErrorMessage = ValidationMessages.TitleRequired)]
        [MinLength(2, ErrorMessage = ValidationMessages.TitleMinLength)]
        [MaxLength(200, ErrorMessage = ValidationMessages.TitleMaxLength)]
        public string? Title { get; set; }

        [MaxLength(1000, ErrorMessage = ValidationMessages.DescriptionMaxLength1000)]
        public string? Description { get; set; }

        public IEnumerable<ValidationResult> Validate(ValidationContext validationContext)
        {
            foreach (var result in BagOrBeltReferenceValidation.ValidateExactlyOne(BagID, BeltID, "Outfit ideja"))
            {
                yield return result;
            }
        }
    }
}
