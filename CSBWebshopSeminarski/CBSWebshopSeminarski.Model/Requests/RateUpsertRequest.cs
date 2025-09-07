namespace CBSWebshopSeminarski.Model.Requests
{
    public class RateUpsertRequest
    {
        public int UserID { get; set; }
        public int BagID { get; set; }
        public int BeltID { get; set; }
        public int Rating { get; set; }
    }
}
