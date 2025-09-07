namespace CBSWebshopSeminarski.Model.Events
{
    public class OrderCreatedEvent
    {
        public int OrderID { get; set; }
        public string OrderNumber { get; set; } = string.Empty;
        public int UserID { get; set; }
        public string? UserEmail { get; set; }
        public decimal Amount { get; set; }
        public DateTime CreatedAtUtc { get; set; } = DateTime.UtcNow;
    }
}
