using System.ComponentModel.DataAnnotations;

namespace CBSWebshopSeminarski.Model.Requests
{
    public class OrderUpsertRequest
    {
        public int OrderID { get; set; }
        
        public string OrderNumber { get; set; } = null!;

        public DateTime Date { get; set; }
        
        /// <summary>
        /// Samo za admin ažuriranje — buyer koristi <see cref="CreateOrderRequest"/>.
        /// Server računa total iz stavki narudžbe.
        /// </summary>
        [Range(typeof(decimal), "0.01", "79228162514264337593543950335", ErrorMessage = "Price must be greater than zero.")]
        public decimal? Price { get; set; }

        /// <summary>
        /// Samo za admin — buyer Create endpoint postavlja ID iz JWT tokena.
        /// </summary>
        [Range(1, int.MaxValue, ErrorMessage = "User ID must be valid.")]
        public int UserID { get; set; }
        
        public List<OrderItemUpsertRequest> items { get; set; } = new List<OrderItemUpsertRequest>();
        public string? TrackingNumber { get; set; }
        public string? CarrierCode { get; set; }
        public DateTime? EstimatedDeliveryDate { get; set; }
    }
}
