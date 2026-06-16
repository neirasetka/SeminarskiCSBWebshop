using System.ComponentModel.DataAnnotations;

namespace CBSWebshopSeminarski.Model.Requests
{
    public class UserSearchRequest : PagedSearchRequest
    {
        [MaxLength(100, ErrorMessage = "Username filter can be up to 100 characters.")]
        public string? UserName { get; set; }
    }
}
