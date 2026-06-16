using System.ComponentModel.DataAnnotations;
using CBSWebshopSeminarski.Model;

namespace CBSWebshopSeminarski.Model.Requests
{
    public class OrderSearchRequest : PagedSearchRequest
    {
        /// <summary>Optional filter; when omitted (e.g. GET /api/Orders with no query), list all.</summary>
        [MaxLength(100, ErrorMessage = ValidationMessages.OrderNumberFilterMaxLength)]
        public string? OrderNumber { get; set; }
    }
}
