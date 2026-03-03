namespace CBSWebshopSeminarski.Model.Models
{
    public class Review
    {
        public int ReviewID { get; set; }
        public string Comment { get; set; } = null!;
        public DateTime Date { get; set; }
        public User User { get; set; } = null!;
        public int UserID { get; set; }
        public int BagID { get; set; }
        public int BeltID { get; set; }
        public ReviewStatus Status { get; set; }
    }
}
