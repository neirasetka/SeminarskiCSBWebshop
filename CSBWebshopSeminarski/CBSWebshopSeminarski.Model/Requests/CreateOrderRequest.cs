using System.ComponentModel.DataAnnotations;
using CBSWebshopSeminarski.Model;

namespace CBSWebshopSeminarski.Model.Requests
{
    public class CreateOrderRequest
    {
        [MaxLength(50, ErrorMessage = ValidationMessages.OrderNumberMaxLength)]
        public string? OrderNumber { get; set; }

        public DateTime? Date { get; set; }
    }
}
