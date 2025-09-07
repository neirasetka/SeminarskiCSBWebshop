using CBSWebshopSeminarski.Model.Models;

namespace CBSWebshopSeminarski.Model.Requests
{
    public class ReviewUpsertRequest
    {
        public int UserID { get; set; }
        public int BagID { get; set; }
        public int BeltID { get; set; }
        public string Comment { get; set; }
        public User Users { get; set; }
        public DateTime Date { get; set; }
    }
}
