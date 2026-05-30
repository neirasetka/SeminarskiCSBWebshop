namespace CBSWebshopSeminarski.Model.Requests
{
    public class BagTypeSearchRequest : PagedSearchRequest
    {
        public string? BagName { get; set; }
    }
}
