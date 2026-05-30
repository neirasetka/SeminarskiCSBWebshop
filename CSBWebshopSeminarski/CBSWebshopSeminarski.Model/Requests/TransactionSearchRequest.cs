namespace CBSWebshopSeminarski.Model.Requests
{
    public class TransactionSearchRequest : PagedSearchRequest
    {
        public int UserID { get; set; }
        public int OrderID { get; set; }
        public DateTime? From { get; set; }
        public DateTime? To { get; set; }
        public string? OrderNumber { get; set; }
    }
}
