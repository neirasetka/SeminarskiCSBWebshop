using System.ComponentModel.DataAnnotations;

namespace CBSWebshopSeminarski.Model.Requests
{
    public class GiveawaySearchRequest : PagedSearchRequest
    {
        /// <summary>active, closed, all — prazno = svi.</summary>
        [MaxLength(20, ErrorMessage = "Status filter can be up to 20 characters.")]
        [RegularExpression(@"^(|active|closed|all)$", ErrorMessage = "Status must be active, closed, or all.")]
        public string? Status { get; set; }
    }
}
