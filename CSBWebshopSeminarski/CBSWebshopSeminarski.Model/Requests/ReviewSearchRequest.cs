namespace CBSWebshopSeminarski.Model.Requests
{
    public class ReviewSearchRequest
    {
        public int UserID { get; set; }
        public int BagID { get; set; }
        public int BeltID { get; set; }
        public string Comment { get; set; } = null!;
        public DateTime Date { get; set; }
        public Models.ReviewStatus? Status { get; set; }
    }
}
