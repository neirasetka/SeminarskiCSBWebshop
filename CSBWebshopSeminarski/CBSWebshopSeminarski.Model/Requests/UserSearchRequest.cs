using System.ComponentModel.DataAnnotations;
using CBSWebshopSeminarski.Model;

namespace CBSWebshopSeminarski.Model.Requests
{
    public class UserSearchRequest : PagedSearchRequest
    {
        [MaxLength(100, ErrorMessage = ValidationMessages.UsernameFilterMaxLength)]
        public string? UserName { get; set; }
    }
}
