using CBSWebshopSeminarski.Model.Models;

namespace CBSWebshopSeminarski.Model.Requests
{
    public class PurchaseUpsertRequest
    {
        public int PurchaseID { get; set; }
        public int UserID { get; set; }
        public int OrderID { get; set; }
        public DateTime PurchaseDate { get; set; }
        public float Price { get; set; }
        public string UserName { get; set; } = null!;
        public string OrderNumber { get; set; } = null!;
        public virtual User User { get; set; } = null!;
        public virtual Order Order { get; set; } = null!;
        public string StripeId { get; set; } = null!;
    }
}
