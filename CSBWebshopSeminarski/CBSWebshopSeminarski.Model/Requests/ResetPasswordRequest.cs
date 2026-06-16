using System.ComponentModel.DataAnnotations;

namespace CBSWebshopSeminarski.Model.Requests
{
    public class ResetPasswordRequest
    {
        [Required(ErrorMessage = "Reset code is required.")]
        [RegularExpression(@"^\d{6}$", ErrorMessage = "Reset code must be exactly 6 digits.")]
        public string Token { get; set; } = null!;

        [Required(ErrorMessage = "New password is required.")]
        [MinLength(6, ErrorMessage = "Password must have at least 6 characters.")]
        public string NewPassword { get; set; } = null!;

        [Required(ErrorMessage = "Password confirmation is required.")]
        [Compare(nameof(NewPassword), ErrorMessage = "Passwords do not match.")]
        public string ConfirmPassword { get; set; } = null!;
    }
}
