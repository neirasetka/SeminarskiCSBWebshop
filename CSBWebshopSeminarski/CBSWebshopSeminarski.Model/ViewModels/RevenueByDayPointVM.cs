namespace CBSWebshopSeminarski.Model.ViewModels
{
    public class RevenueByDayPointVM
    {
        public DateTime DayUtc { get; set; }
        public decimal Revenue { get; set; }
        public int NumPurchases { get; set; }
    }
}