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
        public Order Order { get; set; }
        public string OrderNumber { get; set; }
        public DateTime TransactionDate { get; set; }
        public string TransactionDateString { get; set; }
        public string UserName { get; set; }
        public string BagName { get; set; }
        public string BeltName { get; set; }
        public virtual User User { get; set; }
    }
}
