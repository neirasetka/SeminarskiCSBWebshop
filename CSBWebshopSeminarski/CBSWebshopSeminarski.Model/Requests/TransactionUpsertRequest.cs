namespace CBSWebshopSeminarski.Model.Requests
{
    public class TransactionUpsertRequest
    {
        public int UserID { get; set; }
        public DateTime TransactionDate { get; set; }
        public float Price { get; set; }
        public string OrderNumber { get; set; }
        public string UserName { get; set; }
        public int OrderID { get; set; }
    }
}
