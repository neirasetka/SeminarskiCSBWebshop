namespace CBSWebshopSeminarski.Model.Requests
{
    public class BeltSearchRequest : PagedSearchRequest
    {
        public int UserID { get; set; }
        public int? BeltTypeID { get; set; }
        public string? BeltName { get; set; }
    }
}
