using System.ComponentModel.DataAnnotations;
using CBSWebshopSeminarski.Model;

namespace CBSWebshopSeminarski.Model.Requests
{
    /// <summary>
    /// Ažuriranje vlastitog profila (bez lozinke i uloga). Koristi se s JWT, ne zahtijeva Admin.
    /// </summary>
    public class UserProfileUpdateRequest
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

        public byte[]? Image { get; set; }
    }
}
