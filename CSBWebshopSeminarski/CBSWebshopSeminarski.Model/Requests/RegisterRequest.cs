using System.ComponentModel.DataAnnotations;
using CBSWebshopSeminarski.Model;

namespace CBSWebshopSeminarski.Model.Requests
{
    public class RegisterRequest
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

        [Required(ErrorMessage = ValidationMessages.PasswordRequired)]
        [MinLength(6, ErrorMessage = ValidationMessages.PasswordMinLength)]
        public string Password { get; set; } = null!;

        [Compare(nameof(Password), ErrorMessage = ValidationMessages.PasswordsDoNotMatch)]
        public string PasswordConfirmation { get; set; } = null!;

        public byte[]? Image { get; set; }
    }
}
