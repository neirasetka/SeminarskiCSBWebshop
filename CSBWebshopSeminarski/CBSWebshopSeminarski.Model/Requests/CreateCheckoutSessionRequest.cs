using System.ComponentModel.DataAnnotations;
using CBSWebshopSeminarski.Model;

namespace CBSWebshopSeminarski.Model.Requests
{
    public class CreateCheckoutSessionRequest
    {
        [Required(ErrorMessage = ValidationMessages.OrderIdRequired)]
        [Range(1, int.MaxValue, ErrorMessage = ValidationMessages.OrderIdValid)]
        public int OrderID { get; set; }

        [EmailAddress(ErrorMessage = ValidationMessages.EmailInvalid)]
        public string? ReceiptEmail { get; set; }
    }
}
