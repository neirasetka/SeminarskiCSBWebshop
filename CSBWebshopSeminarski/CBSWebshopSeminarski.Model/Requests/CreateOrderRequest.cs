using System.ComponentModel.DataAnnotations;

namespace CBSWebshopSeminarski.Model.Requests
{
    public class CreateOrderRequest
    {
        [MaxLength(50, ErrorMessage = "Order number must not exceed 50 characters.")]
        public string? OrderNumber { get; set; }

        public DateTime? Date { get; set; }
    }
}
