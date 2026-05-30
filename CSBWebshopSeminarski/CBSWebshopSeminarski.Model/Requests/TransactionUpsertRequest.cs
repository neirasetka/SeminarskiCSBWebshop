using System.ComponentModel.DataAnnotations;

namespace CBSWebshopSeminarski.Model.Requests
{
    public class TransactionUpsertRequest
    {
        [Range(1, int.MaxValue, ErrorMessage = "User ID must be valid.")]
        public int UserID { get; set; }

        [Required(ErrorMessage = "Transaction date is required.")]
        public DateTime TransactionDate { get; set; }

        [Range(0.01, 100_000_000, ErrorMessage = "Price must be greater than zero.")]
        public decimal Price { get; set; }

        [Required(ErrorMessage = "Order number is required.")]
        public string OrderNumber { get; set; } = null!;

        [Required(ErrorMessage = "Username is required.")]
        [MinLength(3, ErrorMessage = "Username must have at least 3 characters.")]
        public string UserName { get; set; } = null!;

        [Range(1, int.MaxValue, ErrorMessage = "Order ID must be valid.")]
        public int OrderID { get; set; }
    }
}
