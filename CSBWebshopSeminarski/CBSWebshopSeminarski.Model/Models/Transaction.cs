namespace CBSWebshopSeminarski.Model.Models
{
    public class Transaction
    {
        public int TransactionID { get; set; }
        public int UserID { get; set; }
        public User User { get; set; }
        public int BagID { get; set; }
        public int BeltID { get; set; }
        public Belt Bag { get; set; }
        public Belt Belt { get; set; }
        public int OrderID { get; set; }
        public Order Order { get; set; }
        public string OrderNumber { get; set; }
        public DateTime TransactionDate { get; set; }
        public string TransactionDateString { get; set; }
        public float Price { get; set; }
        public string UserName { get; set; }
    }
}
