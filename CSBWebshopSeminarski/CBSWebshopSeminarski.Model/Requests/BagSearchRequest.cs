using System.ComponentModel.DataAnnotations;
using CBSWebshopSeminarski.Model;

namespace CBSWebshopSeminarski.Model.Requests
{
    public class BagSearchRequest : PagedSearchRequest
    {
        public int UserID { get; set; }

        public int? BagTypeID { get; set; }

        [MaxLength(200, ErrorMessage = ValidationMessages.BagNameFilterMaxLength)]
        public string? BagName { get; set; }
    }
}
