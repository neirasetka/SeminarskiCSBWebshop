using System.ComponentModel.DataAnnotations;

namespace CBSWebshopSeminarski.Model.Requests
{
    public class RequestPasswordResetRequest
    {
        [Required]
        [EmailAddress]
        public string Email { get; set; } = null!;
    }
}
