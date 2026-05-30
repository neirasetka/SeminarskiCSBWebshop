using System.ComponentModel.DataAnnotations;

namespace CBSWebshopSeminarski.Model.Requests
{
    public class PurchaseUpsertRequest
    {
        [Range(1, int.MaxValue, ErrorMessage = "Purchase ID must be valid.")]
        public int PurchaseID { get; set; }

        [Range(1, int.MaxValue, ErrorMessage = "User ID must be valid.")]
        public int UserID { get; set; }

        [Range(1, int.MaxValue, ErrorMessage = "Order ID must be valid.")]
        public int OrderID { get; set; }

        [Required(ErrorMessage = "Purchase date is required.")]
        public DateTime PurchaseDate { get; set; }

        [Range(0.01, 100_000_000, ErrorMessage = "Price must be greater than zero.")]
        public decimal Price { get; set; }

        [Required(ErrorMessage = "Username is required.")]
        [MinLength(3, ErrorMessage = "Username must have at least 3 characters.")]
        public string UserName { get; set; } = null!;

        [Required(ErrorMessage = "Order number is required.")]
        public string OrderNumber { get; set; } = null!;

        [Required(ErrorMessage = "Stripe ID is required.")]
        public string StripeId { get; set; } = null!;
    }
}
