using System.ComponentModel.DataAnnotations;

namespace CBSWebshopSeminarski.Model.Requests
{
    public class BeltSearchRequest : PagedSearchRequest
    {
        public int UserID { get; set; }

        public int? BeltTypeID { get; set; }

        [MaxLength(200, ErrorMessage = "Belt name filter can be up to 200 characters.")]
        public string? BeltName { get; set; }
    }
}
