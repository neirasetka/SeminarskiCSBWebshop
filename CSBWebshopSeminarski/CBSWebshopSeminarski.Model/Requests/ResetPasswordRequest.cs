using System.ComponentModel.DataAnnotations;
using CBSWebshopSeminarski.Model;

namespace CBSWebshopSeminarski.Model.Requests
{
    public class ResetPasswordRequest
    {
        [Required(ErrorMessage = ValidationMessages.ResetCodeRequired)]
        [RegularExpression(@"^\d{6}$", ErrorMessage = ValidationMessages.ResetCodeFormat)]
        public string Token { get; set; } = null!;

        [Required(ErrorMessage = ValidationMessages.NewPasswordRequired)]
        [MinLength(6, ErrorMessage = ValidationMessages.PasswordMinLength)]
        public string NewPassword { get; set; } = null!;

        [Required(ErrorMessage = ValidationMessages.PasswordConfirmRequired)]
        [Compare(nameof(NewPassword), ErrorMessage = ValidationMessages.PasswordsDoNotMatch)]
        public string ConfirmPassword { get; set; } = null!;
    }
}
