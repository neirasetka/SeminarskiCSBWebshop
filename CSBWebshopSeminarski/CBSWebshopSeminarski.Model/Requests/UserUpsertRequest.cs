using System.ComponentModel.DataAnnotations;
using CBSWebshopSeminarski.Model;

namespace CBSWebshopSeminarski.Model.Requests
{
    public class UserUpsertRequest : IValidatableObject
    {
        [Required(ErrorMessage = ValidationMessages.NameRequired)]
        [MinLength(2, ErrorMessage = ValidationMessages.NameMinLength)]
        public string Name { get; set; } = null!;

        [Required(ErrorMessage = ValidationMessages.SurnameRequired)]
        [MinLength(2, ErrorMessage = ValidationMessages.SurnameMinLength)]
        public string Surname { get; set; } = null!;

        [Required(ErrorMessage = ValidationMessages.EmailRequired)]
        [EmailAddress(ErrorMessage = ValidationMessages.EmailInvalid)]
        public string Email { get; set; } = null!;

        [RegularExpression(ValidationPatterns.Phone, ErrorMessage = ValidationPatterns.PhoneErrorMessage)]
        public string Phone { get; set; } = string.Empty;

        [Required(ErrorMessage = ValidationMessages.UsernameRequired)]
        [MinLength(3, ErrorMessage = ValidationMessages.UsernameMinLength)]
        public string UserName { get; set; } = null!;

        [MinLength(6, ErrorMessage = ValidationMessages.PasswordMinLength)]
        public string Password { get; set; } = null!;

        public string PasswordConfirmation { get; set; } = null!;
        /// <summary>Optional for registration. Service uses empty array when null.</summary>
        public byte[]? Image { get; set; }
        public List<string> RoleNames { get; set; } = new List<string>();
        public List<string> RoleNamesDelete { get; set; } = new List<string>();

        public IEnumerable<ValidationResult> Validate(ValidationContext validationContext)
        {
            if (!string.IsNullOrEmpty(Password) && Password != PasswordConfirmation)
            {
                yield return new ValidationResult(
                    ValidationMessages.PasswordsDoNotMatch,
                    new[] { nameof(PasswordConfirmation) });
            }
        }
    }
}
