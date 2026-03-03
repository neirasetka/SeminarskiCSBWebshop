using System.ComponentModel.DataAnnotations;

namespace CBSWebshopSeminarski.Model.Requests
{
    public class UserAuthenticationRequest
    {
        [Required(ErrorMessage = "Username is required.")]
        public string UserName { get; set; } = null!;
        
        [Required(ErrorMessage = "Password is required.")]
        public string Password { get; set; } = null!;
    }
}
