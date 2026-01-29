using System.ComponentModel.DataAnnotations;

namespace CBSWebshopSeminarski.Model.Requests
{
    public class UserAuthenticationRequest
    {
        [Required(ErrorMessage = "Korisničko ime je obavezno")]
        public string UserName { get; set; }
        
        [Required(ErrorMessage = "Lozinka je obavezna")]
        public string Password { get; set; }
    }
}
