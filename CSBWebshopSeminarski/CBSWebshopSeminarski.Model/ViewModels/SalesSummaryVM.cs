namespace CBSWebshopSeminarski.Model.ViewModels
{
    public class SalesSummaryVM
    {
        public int TotalOrders { get; set; }
        public int TotalPurchases { get; set; }
        public decimal TotalRevenue { get; set; }
        public decimal AverageOrderValue { get; set; }
        public DateTime? FromDateUtc { get; set; }
        public DateTime? ToDateUtc { get; set; }
    }
}