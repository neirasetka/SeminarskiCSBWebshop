using CBSWebshopSeminarski.Model.Models;

namespace CBSWebshopSeminarski.Model.ViewModels
{
    public class TransactionsListVM
    {
        public int PurchaseID { get; set; }
        public int UserID { get; set; }
        public int OrderID { get; set; }
        public DateTime PurchaseDate { get; set; }
        public float Price { get; set; }
        public Order Order { get; set; } = null!;
        public string OrderNumber { get; set; } = null!;
        public DateTime TransactionDate { get; set; }
        public string TransactionDateString { get; set; } = null!;
        public string UserName { get; set; } = null!;
        public string BagName { get; set; } = null!;
        public string BeltName { get; set; } = null!;
        public virtual User User { get; set; } = null!;
    }
}
