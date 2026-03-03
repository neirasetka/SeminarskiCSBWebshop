namespace CBSWebshopSeminarski.Model.Models
{
    public class Transaction
    {
        public int TransactionID { get; set; }
        public int UserID { get; set; }
        public User User { get; set; } = null!;
        public int BagID { get; set; }
        public int BeltID { get; set; }
        public Belt Bag { get; set; } = null!;
        public Belt Belt { get; set; } = null!;
        public int OrderID { get; set; }
        public Order Order { get; set; } = null!;
        public string OrderNumber { get; set; } = null!;
        public DateTime TransactionDate { get; set; }
        public string TransactionDateString { get; set; } = null!;
        public float Price { get; set; }
        public string UserName { get; set; } = null!;
    }
}
