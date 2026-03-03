namespace CBSWebshopSeminarski.Model.Requests
{
    public class TransactionUpsertRequest
    {
        public int UserID { get; set; }
        public DateTime TransactionDate { get; set; }
        public float Price { get; set; }
        public string OrderNumber { get; set; } = null!;
        public string UserName { get; set; } = null!;
        public int OrderID { get; set; }
    }
}
