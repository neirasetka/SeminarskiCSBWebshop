using System.ComponentModel.DataAnnotations;
using CBSWebshopSeminarski.Model;

namespace CBSWebshopSeminarski.Model.Requests
{
    public class LookbookSearchRequest : PagedSearchRequest
    {
        public int? BagID { get; set; }

        public int? BeltID { get; set; }

        public bool? IsFeatured { get; set; }

        [MaxLength(100, ErrorMessage = ValidationMessages.TagFilterMaxLength)]
        public string? Tag { get; set; }

        [MaxLength(200, ErrorMessage = ValidationMessages.TitleFilterMaxLength)]
        public string? Title { get; set; }

        public CBSWebshopSeminarski.Model.Models.OccasionType? Occasion { get; set; }

        public CBSWebshopSeminarski.Model.Models.StyleType? Style { get; set; }

        public CBSWebshopSeminarski.Model.Models.SeasonType? Season { get; set; }
    }
}
