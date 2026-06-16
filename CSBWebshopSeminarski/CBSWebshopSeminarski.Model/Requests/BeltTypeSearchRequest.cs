using System.ComponentModel.DataAnnotations;

namespace CBSWebshopSeminarski.Model.Requests
{
    public class BeltTypeSearchRequest : PagedSearchRequest
    {
        [MaxLength(200, ErrorMessage = "Belt type name filter can be up to 200 characters.")]
        public string? BeltName { get; set; }
    }
}
