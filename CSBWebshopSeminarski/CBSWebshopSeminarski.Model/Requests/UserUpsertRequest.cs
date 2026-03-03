using System.ComponentModel.DataAnnotations;

namespace CBSWebshopSeminarski.Model.Requests
{
    public class UserUpsertRequest
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
        
        [Phone(ErrorMessage = "Please enter a valid phone number.")]
        public string Phone { get; set; } = null!;
        
        [Required(ErrorMessage = "Username is required.")]
        [MinLength(3, ErrorMessage = "Username must have at least 3 characters.")]
        public string UserName { get; set; } = null!;
        
        [MinLength(6, ErrorMessage = "Password must have at least 6 characters.")]
        public string Password { get; set; } = null!;
        
        public string PasswordConfirmation { get; set; } = null!;
        public byte[] Image { get; set; } = null!;
        public List<int> Roles { get; set; } = new List<int>();
        public List<int> RolesDelete { get; set; } = new List<int>();
    }
}
