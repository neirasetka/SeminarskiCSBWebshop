using System.ComponentModel.DataAnnotations;

namespace CBSWebshopSeminarski.Model.Requests
{
    public class UserUpsertRequest
    {
        [Required(ErrorMessage = "Name is required.")]
        [MinLength(2, ErrorMessage = "Name must have at least 2 characters.")]
        public string Name { get; set; }
        
        [Required(ErrorMessage = "Surname is required.")]
        [MinLength(2, ErrorMessage = "Last name must have at least 2 characters.")]
        public string Surname { get; set; }
        
        [Required(ErrorMessage = "Email is required.")]
        [EmailAddress(ErrorMessage = "Please enter a valid email address.")]
        public string Email { get; set; }
        
        [Phone(ErrorMessage = "Please enter a valid phone number.")]
        public string Phone { get; set; }
        
        [Required(ErrorMessage = "Username is required.")]
        [MinLength(3, ErrorMessage = "Username must have at least 3 characters.")]
        public string UserName { get; set; }
        
        [MinLength(6, ErrorMessage = "Password must have at least 6 characters.")]
        public string Password { get; set; }
        
        public string PasswordConfirmation { get; set; }
        public byte[] Image { get; set; }
        public List<int> Roles { get; set; } = new List<int>();
        public List<int> RolesDelete { get; set; } = new List<int>();
    }
}
