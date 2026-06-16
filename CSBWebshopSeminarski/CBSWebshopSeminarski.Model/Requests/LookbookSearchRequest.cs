using System.ComponentModel.DataAnnotations;

namespace CBSWebshopSeminarski.Model.Requests
{
    public class LookbookSearchRequest : PagedSearchRequest
    {
        public int? BagID { get; set; }

        public int? BeltID { get; set; }

        public bool? IsFeatured { get; set; }

        [MaxLength(100, ErrorMessage = "Tag filter can be up to 100 characters.")]
        public string? Tag { get; set; }

        [MaxLength(200, ErrorMessage = "Title filter can be up to 200 characters.")]
        public string? Title { get; set; }

        public CBSWebshopSeminarski.Model.Models.OccasionType? Occasion { get; set; }

        public CBSWebshopSeminarski.Model.Models.StyleType? Style { get; set; }

        public CBSWebshopSeminarski.Model.Models.SeasonType? Season { get; set; }
    }
}
