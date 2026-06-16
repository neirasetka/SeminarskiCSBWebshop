using System.ComponentModel.DataAnnotations;
using CBSWebshopSeminarski.Model;

namespace CBSWebshopSeminarski.Model.Requests
{
    public class BeltTypeSearchRequest : PagedSearchRequest
    {
        [MaxLength(200, ErrorMessage = ValidationMessages.BeltTypeNameFilterMaxLength)]
        public string? BeltName { get; set; }
    }
}
