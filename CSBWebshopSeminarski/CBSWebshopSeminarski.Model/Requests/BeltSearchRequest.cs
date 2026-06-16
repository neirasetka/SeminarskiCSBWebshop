using System.ComponentModel.DataAnnotations;
using CBSWebshopSeminarski.Model;

namespace CBSWebshopSeminarski.Model.Requests
{
    public class BeltSearchRequest : PagedSearchRequest
    {
        public int UserID { get; set; }

        public int? BeltTypeID { get; set; }

        [MaxLength(200, ErrorMessage = ValidationMessages.BeltNameFilterMaxLength)]
        public string? BeltName { get; set; }
    }
}
