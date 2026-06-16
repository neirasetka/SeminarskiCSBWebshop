using System.ComponentModel.DataAnnotations;
using CBSWebshopSeminarski.Model;

namespace CBSWebshopSeminarski.Model.Requests
{
    public class BagTypeSearchRequest : PagedSearchRequest
    {
        [MaxLength(200, ErrorMessage = ValidationMessages.BagTypeNameFilterMaxLength)]
        public string? BagName { get; set; }
    }
}
