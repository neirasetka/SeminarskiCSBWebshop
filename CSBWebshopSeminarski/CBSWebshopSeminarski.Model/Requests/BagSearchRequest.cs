namespace CBSWebshopSeminarski.Model.Requests
{
    public class BagSearchRequest : PagedSearchRequest
    {
        public int UserID { get; set; }
        public int? BagTypeID { get; set; }
        public string? BagName { get; set; }
    }
}
