using System.ComponentModel.DataAnnotations;
using CBSWebshopSeminarski.Model;

namespace CBSWebshopSeminarski.Model.Requests
{
    public class OutfitIdeaSearchRequest : PagedSearchRequest
    {
        public int? BagID { get; set; }

        public int? BeltID { get; set; }

        public int? UserID { get; set; }

        [MaxLength(200, ErrorMessage = ValidationMessages.TitleFilterMaxLength)]
        public string? Title { get; set; }
    }
}
