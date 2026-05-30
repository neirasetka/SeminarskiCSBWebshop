namespace CBSWebshopSeminarski.Model.Requests
{
    public class BeltTypeSearchRequest : PagedSearchRequest
    {
        public string? BeltName { get; set; }
    }
}
