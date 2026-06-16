using System.ComponentModel.DataAnnotations;
using CBSWebshopSeminarski.Model;

namespace CBSWebshopSeminarski.Model.Requests
{
    public class ReviewSearchRequest : PagedSearchRequest
    {
        public int UserID { get; set; }

        public int? BagID { get; set; }

        public int? BeltID { get; set; }

        [MaxLength(500, ErrorMessage = ValidationMessages.CommentFilterMaxLength)]
        public string? Comment { get; set; }

        public DateTime Date { get; set; }

        public Models.ReviewStatus? Status { get; set; }
    }
}
