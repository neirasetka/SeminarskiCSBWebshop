namespace CBSWebshopSeminarski.Model.Models
{
    public class RecommendedProductDto
    {
        public int ProductId { get; set; }
        public string ProductName { get; set; } = null!;
        public string ProductType { get; set; } = null!;
        public string Description { get; set; } = null!;
        public decimal Price { get; set; }
        public byte[] Image { get; set; } = null!;
        public double Score { get; set; }
        public string Reason { get; set; } = null!;
        /// <summary>
        /// True when recommendation is based on user profile (favorites, ratings, purchases).
        /// False for cold-start fallback (popular products).
        /// </summary>
        public bool IsPersonalized { get; set; }
    }
}
