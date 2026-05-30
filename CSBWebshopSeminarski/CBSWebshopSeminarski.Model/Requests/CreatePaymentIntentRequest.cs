using System.ComponentModel.DataAnnotations;

namespace CBSWebshopSeminarski.Model.Requests
{
    public class CreatePaymentIntentRequest
    {
        [Required]
        [Range(1, int.MaxValue, ErrorMessage = "Order ID must be valid.")]
        public int OrderID { get; set; }

        [EmailAddress(ErrorMessage = "Please enter a valid email address.")]
        public string? ReceiptEmail { get; set; }
    }
}
