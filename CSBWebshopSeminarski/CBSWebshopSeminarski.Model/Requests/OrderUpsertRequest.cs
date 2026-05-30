using System.ComponentModel.DataAnnotations;

namespace CBSWebshopSeminarski.Model.Requests
{
    public class OrderUpsertRequest
    {
        public int OrderID { get; set; }
        
        [Required(ErrorMessage = "Order ID is required.")]
        public string OrderNumber { get; set; } = null!;
        
        [Required(ErrorMessage = "Date is required.")]
        public DateTime Date { get; set; }
        
        /// <summary>
        /// Opcionalno pri kreiranju prazne korpe — server postavlja 0 dok nema stavki.
        /// Kad je poslano, mora biti veće od 0.
        /// </summary>
        [Range(0.01, double.MaxValue, ErrorMessage = "Price must be greater than zero.")]
        public decimal? Price { get; set; }
        
        [Required(ErrorMessage = "User ID is required.")]
        [Range(1, int.MaxValue, ErrorMessage = "User ID must be valid.")]
        public int UserID { get; set; }
        
        public List<OrderItemUpsertRequest> items { get; set; } = new List<OrderItemUpsertRequest>();
        public string? TrackingNumber { get; set; }
        public string? CarrierCode { get; set; }
        public DateTime? EstimatedDeliveryDate { get; set; }
    }
}
