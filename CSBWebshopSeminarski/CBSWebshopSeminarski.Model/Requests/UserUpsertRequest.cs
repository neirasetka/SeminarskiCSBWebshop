using System.ComponentModel.DataAnnotations;
using CBSWebshopSeminarski.Model;

namespace CBSWebshopSeminarski.Model.Requests
{
    public class UserUpsertRequest : IValidatableObject
    {
        [Required(ErrorMessage = "Name is required.")]
        [MinLength(2, ErrorMessage = "Name must have at least 2 characters.")]
        public string Name { get; set; } = null!;
        
        [Required(ErrorMessage = "Surname is required.")]
        [MinLength(2, ErrorMessage = "Last name must have at least 2 characters.")]
        public string Surname { get; set; } = null!;
        
        [Required(ErrorMessage = "Email is required.")]
        [EmailAddress(ErrorMessage = "Please enter a valid email address.")]
        public string Email { get; set; } = null!;
        
        [RegularExpression(ValidationPatterns.Phone, ErrorMessage = ValidationPatterns.PhoneErrorMessage)]
        public string Phone { get; set; } = string.Empty;
        
        [Required(ErrorMessage = "Username is required.")]
        [MinLength(3, ErrorMessage = "Username must have at least 3 characters.")]
        public string UserName { get; set; } = null!;
        
        [MinLength(6, ErrorMessage = "Password must have at least 6 characters.")]
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
                    "Passwords do not match.",
                    new[] { nameof(PasswordConfirmation) });
            }
        }
    }
}
