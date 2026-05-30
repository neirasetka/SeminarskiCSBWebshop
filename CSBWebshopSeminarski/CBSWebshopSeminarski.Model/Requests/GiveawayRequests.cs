using System.ComponentModel.DataAnnotations;

namespace CBSWebshopSeminarski.Model.Requests
{
    public class CreateGiveawayRequest : IValidatableObject
    {
        [Required(ErrorMessage = "Title is required.")]
        [MinLength(2, ErrorMessage = "Title must be at least 2 characters long.")]
        [MaxLength(200, ErrorMessage = "Title can be up to 200 characters.")]
        public string Title { get; set; } = string.Empty;

        [Required(ErrorMessage = "Start date is required.")]
        public DateTime StartDate { get; set; }

        [Required(ErrorMessage = "End date is required.")]
        public DateTime EndDate { get; set; }

        public IEnumerable<ValidationResult> Validate(ValidationContext validationContext)
        {
            if (EndDate <= StartDate)
            {
                yield return new ValidationResult(
                    "End date must be after start date.",
                    new[] { nameof(EndDate) });
            }
        }
    }

    public class UpdateGiveawayDurationRequest : IValidatableObject
    {
        [Required(ErrorMessage = "Start date is required.")]
        public DateTime StartDate { get; set; }

        [Required(ErrorMessage = "End date is required.")]
        public DateTime EndDate { get; set; }

        public IEnumerable<ValidationResult> Validate(ValidationContext validationContext)
        {
            if (EndDate <= StartDate)
            {
                yield return new ValidationResult(
                    "End date must be after start date.",
                    new[] { nameof(EndDate) });
            }
        }
    }

    public class RegisterParticipantRequest
    {
        [MinLength(2, ErrorMessage = "Name must be at least 2 characters long.")]
        [MaxLength(100, ErrorMessage = "Name can be up to 100 characters.")]
        public string? Name { get; set; }

        [Required(ErrorMessage = "Email is required.")]
        [EmailAddress(ErrorMessage = "Please enter a valid email address.")]
        public string Email { get; set; } = string.Empty;
    }
}
