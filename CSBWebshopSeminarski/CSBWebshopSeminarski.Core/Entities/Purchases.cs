using System.ComponentModel.DataAnnotations;

namespace CSBWebshopSeminarski.Core.Entities
{
    public class Purchases
    {
        [Key]
        public int PurchaseID { get; set; }
        public int UserID { get; set; }
        public int OrderID { get; set; }
        public DateTime PurchaseDate { get; set; }
        public float Price { get; set; }
        public string Username { get; set; } = null!;
        public string OrderNumber { get; set; } = null!;
        public virtual Users User { get; set; } = null!;
        public virtual Orders Order { get; set; } = null!;
        public string StripeId { get; set; } = null!;
    }
}
