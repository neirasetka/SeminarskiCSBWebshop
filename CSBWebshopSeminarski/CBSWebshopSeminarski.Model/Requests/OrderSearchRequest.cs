using System.ComponentModel.DataAnnotations;

namespace CBSWebshopSeminarski.Model.Requests
{
    public class OrderSearchRequest : PagedSearchRequest
    {
        /// <summary>Optional filter; when omitted (e.g. GET /api/Orders with no query), list all.</summary>
        [MaxLength(100, ErrorMessage = "Order number filter can be up to 100 characters.")]
        public string? OrderNumber { get; set; }
    }
}
