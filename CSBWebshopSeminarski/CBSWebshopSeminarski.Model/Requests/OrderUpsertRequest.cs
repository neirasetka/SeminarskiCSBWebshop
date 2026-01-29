using System.ComponentModel.DataAnnotations;

namespace CBSWebshopSeminarski.Model.Requests
{
    public class OrderUpsertRequest
    {
        public int OrderID { get; set; }
        
        [Required(ErrorMessage = "Broj narudžbe je obavezan")]
        public string OrderNumber { get; set; }
        
        [Required(ErrorMessage = "Datum je obavezan")]
        public DateTime Date { get; set; }
        
        [Required(ErrorMessage = "Cijena je obavezna")]
        [Range(0.01, float.MaxValue, ErrorMessage = "Cijena mora biti veća od 0")]
        public float Price { get; set; }
        
        [Required(ErrorMessage = "ID korisnika je obavezan")]
        [Range(1, int.MaxValue, ErrorMessage = "ID korisnika mora biti validan")]
        public int UserID { get; set; }
        
        public List<OrderItemUpsertRequest> items { get; set; } = new List<OrderItemUpsertRequest>();
        public string? TrackingNumber { get; set; }
        public string? CarrierCode { get; set; }
        public DateTime? EstimatedDeliveryDate { get; set; }
    }
}
