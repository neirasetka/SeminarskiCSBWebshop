namespace CBSWebshopSeminarski.Model.Requests
{
    public class RateSearchRequest
    {
        public int UserID { get; set; }
        public int BagID { get; set; }
        public int BeltID { get; set; }
        public int Rating { get; set; }
    }
}
