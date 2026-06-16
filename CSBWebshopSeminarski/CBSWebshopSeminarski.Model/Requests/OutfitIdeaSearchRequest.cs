using System.ComponentModel.DataAnnotations;

namespace CBSWebshopSeminarski.Model.Requests
{
    public class OutfitIdeaSearchRequest : PagedSearchRequest
    {
        public int? BagID { get; set; }

        public int? BeltID { get; set; }

        public int? UserID { get; set; }

        [MaxLength(200, ErrorMessage = "Title filter can be up to 200 characters.")]
        public string? Title { get; set; }
    }
}
