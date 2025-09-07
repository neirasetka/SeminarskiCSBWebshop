namespace CBSWebshopSeminarski.Model.ViewModels
{
    public class TopProductVM
    {
        public string ProductType { get; set; } = string.Empty; // Bag or Belt
        public int ProductId { get; set; }
        public string ProductName { get; set; } = string.Empty;
        public int QuantitySold { get; set; }
        public decimal Revenue { get; set; }
    }
}
