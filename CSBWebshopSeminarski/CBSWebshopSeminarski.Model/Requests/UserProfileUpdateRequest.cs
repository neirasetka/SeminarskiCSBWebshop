using System.ComponentModel.DataAnnotations;
using CBSWebshopSeminarski.Model;

namespace CBSWebshopSeminarski.Model.Requests
{
    /// <summary>
    /// Ažuriranje vlastitog profila (bez lozinke i uloga). Koristi se s JWT, ne zahtijeva Admin.
    /// </summary>
    public class UserProfileUpdateRequest
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

        public byte[]? Image { get; set; }
    }
}
