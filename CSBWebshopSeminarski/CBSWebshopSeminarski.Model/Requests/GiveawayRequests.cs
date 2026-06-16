using System.ComponentModel.DataAnnotations;
using CBSWebshopSeminarski.Model;

namespace CBSWebshopSeminarski.Model.Requests
{
    public class CreateGiveawayRequest : IValidatableObject
    {
        [Required(ErrorMessage = ValidationMessages.TitleRequired)]
        [MinLength(2, ErrorMessage = ValidationMessages.TitleMinLength)]
        [MaxLength(200, ErrorMessage = ValidationMessages.TitleMaxLength)]
        public string Title { get; set; } = string.Empty;

        [Required(ErrorMessage = ValidationMessages.StartDateRequired)]
        public DateTime StartDate { get; set; }

        [Required(ErrorMessage = ValidationMessages.EndDateRequired)]
        public DateTime EndDate { get; set; }

        public IEnumerable<ValidationResult> Validate(ValidationContext validationContext)
        {
            if (EndDate <= StartDate)
            {
                yield return new ValidationResult(
                    "Datum kraja mora biti nakon datuma početka.",
                    new[] { nameof(EndDate) });
            }
        }
    }

    public class UpdateGiveawayDurationRequest : IValidatableObject
    {
        [Required(ErrorMessage = ValidationMessages.StartDateRequired)]
        public DateTime StartDate { get; set; }

        [Required(ErrorMessage = ValidationMessages.EndDateRequired)]
        public DateTime EndDate { get; set; }

        public IEnumerable<ValidationResult> Validate(ValidationContext validationContext)
        {
            if (EndDate <= StartDate)
            {
                yield return new ValidationResult(
                    "Datum kraja mora biti nakon datuma početka.",
                    new[] { nameof(EndDate) });
            }
        }
    }

    public class RegisterParticipantRequest
    {
        [MinLength(2, ErrorMessage = ValidationMessages.ParticipantNameMinLength)]
        [MaxLength(100, ErrorMessage = ValidationMessages.ParticipantNameMaxLength)]
        public string? Name { get; set; }

        [Required(ErrorMessage = ValidationMessages.EmailRequired)]
        [EmailAddress(ErrorMessage = ValidationMessages.EmailInvalid)]
        public string Email { get; set; } = string.Empty;
    }
}
