using System.ComponentModel.DataAnnotations;
using CBSWebshopSeminarski.Model;

namespace CBSWebshopSeminarski.Model.Requests
{
    public class GiveawaySearchRequest : PagedSearchRequest
    {
        /// <summary>active, closed, all — prazno = svi.</summary>
        [MaxLength(20, ErrorMessage = ValidationMessages.GiveawayStatusFilterMaxLength)]
        [RegularExpression(@"^(|active|closed|all)$", ErrorMessage = ValidationMessages.GiveawayStatusFilterValues)]
        public string? Status { get; set; }
    }
}
