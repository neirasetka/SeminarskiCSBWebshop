namespace CBSWebshopSeminarski.Model.Requests
{
    public class OrderSearchRequest : PagedSearchRequest
    {
        /// <summary>Optional filter; when omitted (e.g. GET /api/Orders with no query), list all.</summary>
        public string? OrderNumber { get; set; }
    }
}
