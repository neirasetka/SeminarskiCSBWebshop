using System.ComponentModel.DataAnnotations;

namespace CBSWebshopSeminarski.Model.Requests
{
    public class BagSearchRequest : PagedSearchRequest
    {
        public int UserID { get; set; }

        public int? BagTypeID { get; set; }

        [MaxLength(200, ErrorMessage = "Bag name filter can be up to 200 characters.")]
        public string? BagName { get; set; }
    }
}
