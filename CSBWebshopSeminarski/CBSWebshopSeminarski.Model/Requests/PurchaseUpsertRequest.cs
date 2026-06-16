using System.ComponentModel.DataAnnotations;
using CBSWebshopSeminarski.Model;

namespace CBSWebshopSeminarski.Model.Requests
{
    public class PurchaseUpsertRequest
    {
        [Range(1, int.MaxValue, ErrorMessage = ValidationMessages.PurchaseIdValid)]
        public int PurchaseID { get; set; }

        [Range(1, int.MaxValue, ErrorMessage = ValidationMessages.UserIdValid)]
        public int UserID { get; set; }

        [Range(1, int.MaxValue, ErrorMessage = ValidationMessages.OrderIdValid)]
        public int OrderID { get; set; }

        [Required(ErrorMessage = ValidationMessages.PurchaseDateRequired)]
        public DateTime PurchaseDate { get; set; }

        [Range(typeof(decimal), "0.01", "100000000", ErrorMessage = ValidationMessages.PriceGreaterThanZero)]
        public decimal Price { get; set; }

        [Required(ErrorMessage = ValidationMessages.UsernameRequired)]
        [MinLength(3, ErrorMessage = ValidationMessages.UsernameMinLength)]
        public string UserName { get; set; } = null!;

        [Required(ErrorMessage = ValidationMessages.OrderNumberRequired)]
        public string OrderNumber { get; set; } = null!;

        [Required(ErrorMessage = ValidationMessages.StripeIdRequired)]
        public string StripeId { get; set; } = null!;
    }
}
