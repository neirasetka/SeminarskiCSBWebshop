using System.ComponentModel.DataAnnotations;

namespace CBSWebshopSeminarski.Model.Requests
{
    public class BagTypeSearchRequest : PagedSearchRequest
    {
        [MaxLength(200, ErrorMessage = "Bag type name filter can be up to 200 characters.")]
        public string? BagName { get; set; }
    }
}
