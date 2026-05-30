namespace CBSWebshopSeminarski.Model.Requests
{
    public class FavoriteSearchRequest : PagedSearchRequest
    {
        public int UserID { get; set; }
        public int? BagID { get; set; }
        public int? BeltID { get; set; }
    }
}
