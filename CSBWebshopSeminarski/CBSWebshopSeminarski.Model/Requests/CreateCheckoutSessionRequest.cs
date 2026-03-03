using System.ComponentModel.DataAnnotations;

namespace CBSWebshopSeminarski.Model.Requests
{
    public class CreateCheckoutSessionRequest
    {
        [Required]
        public int OrderID { get; set; }

        public string? SuccessUrl { get; set; }

        public string? CancelUrl { get; set; }

        public string? ReceiptEmail { get; set; }
    }
}
