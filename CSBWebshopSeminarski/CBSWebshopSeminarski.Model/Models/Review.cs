namespace CBSWebshopSeminarski.Model.Models
{
    public class Review
    {
        public int ReviewID { get; set; }
        public string Comment { get; set; }
        public DateTime Date { get; set; }
        public User User { get; set; }
        public int UserID { get; set; }
        public int BagID { get; set; }
        public int BeltID { get; set; }
        public ReviewStatus Status { get; set; }
    }
}
