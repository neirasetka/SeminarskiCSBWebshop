namespace CBSWebshopSeminarski.Model.Requests
{
    public class BagSearchRequest
    {
        public int UserID { get; set; }
        public int? BagTypeID { get; set; }
        public string? BagName { get; set; }
        public int? Page { get; set; }
        public int? PageSize { get; set; }
    }
}
