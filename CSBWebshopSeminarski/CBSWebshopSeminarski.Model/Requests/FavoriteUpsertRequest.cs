namespace CBSWebshopSeminarski.Model.Requests
{
    public class FavoriteUpsertRequest
    {
        public int UserID { get; set; }
        public int? BagID { get; set; }
        public int? BeltID { get; set; }
    }
}
