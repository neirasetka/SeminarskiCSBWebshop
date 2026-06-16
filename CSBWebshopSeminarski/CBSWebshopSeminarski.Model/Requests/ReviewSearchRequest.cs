using System.ComponentModel.DataAnnotations;

namespace CBSWebshopSeminarski.Model.Requests
{
    public class ReviewSearchRequest : PagedSearchRequest
    {
        public int UserID { get; set; }

        public int? BagID { get; set; }

        public int? BeltID { get; set; }

        [MaxLength(500, ErrorMessage = "Comment filter can be up to 500 characters.")]
        public string? Comment { get; set; }

        public DateTime Date { get; set; }

        public Models.ReviewStatus? Status { get; set; }
    }
}
