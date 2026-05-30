namespace CBSWebshopSeminarski.Model.Requests
{
    public class OrderSearchRequest
    {
        /// <summary>Optional filter; when omitted (e.g. GET /api/Orders with no query), list all.</summary>
        public string? OrderNumber { get; set; }
        public int? Page { get; set; }
        public int? PageSize { get; set; }
    }
}
