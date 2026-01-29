using System.ComponentModel.DataAnnotations;

namespace CBSWebshopSeminarski.Model.Requests
{
    public class UserUpsertRequest
    {
        [Required(ErrorMessage = "Ime je obavezno")]
        [MinLength(2, ErrorMessage = "Ime mora imati najmanje 2 znaka")]
        public string Name { get; set; }
        
        [Required(ErrorMessage = "Prezime je obavezno")]
        [MinLength(2, ErrorMessage = "Prezime mora imati najmanje 2 znaka")]
        public string Surname { get; set; }
        
        [Required(ErrorMessage = "Email je obavezan")]
        [EmailAddress(ErrorMessage = "Unesite ispravnu email adresu")]
        public string Email { get; set; }
        
        [Phone(ErrorMessage = "Unesite ispravan broj telefona")]
        public string Phone { get; set; }
        
        [Required(ErrorMessage = "Korisničko ime je obavezno")]
        [MinLength(3, ErrorMessage = "Korisničko ime mora imati najmanje 3 znaka")]
        public string UserName { get; set; }
        
        [MinLength(6, ErrorMessage = "Lozinka mora imati najmanje 6 znakova")]
        public string Password { get; set; }
        
        public string PasswordConfirmation { get; set; }
        public byte[] Image { get; set; }
        public List<int> Roles { get; set; } = new List<int>();
        public List<int> RolesDelete { get; set; } = new List<int>();
    }
}
