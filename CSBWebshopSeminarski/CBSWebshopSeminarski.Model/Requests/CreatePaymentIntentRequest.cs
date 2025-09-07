using System.ComponentModel.DataAnnotations;

namespace CBSWebshopSeminarski.Model.Requests
{
    public class CreatePaymentIntentRequest
    {
        [Required]
        public int OrderID { get; set; }

        [Required]
        public long AmountInCents { get; set; }

        public string? Currency { get; set; } = "eur";

        public string? ReceiptEmail { get; set; }
    }
}
