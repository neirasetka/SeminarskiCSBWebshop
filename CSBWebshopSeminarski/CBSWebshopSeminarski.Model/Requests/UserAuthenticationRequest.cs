using System.ComponentModel.DataAnnotations;
using CBSWebshopSeminarski.Model;

namespace CBSWebshopSeminarski.Model.Requests
{
    public class UserAuthenticationRequest
    {
        [Required(ErrorMessage = ValidationMessages.UsernameRequired)]
        public string UserName { get; set; } = null!;

        [Required(ErrorMessage = ValidationMessages.PasswordRequired)]
        public string Password { get; set; } = null!;
    }
}
