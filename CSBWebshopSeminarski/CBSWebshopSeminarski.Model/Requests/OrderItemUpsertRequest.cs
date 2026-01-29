using System.ComponentModel.DataAnnotations;

namespace CBSWebshopSeminarski.Model.Requests
{
    public class OrderItemUpsertRequest
    {
        public int? BagID { get; set; }
        public int? BeltID { get; set; }
        
        [Required(ErrorMessage = "ID narudžbe je obavezan")]
        [Range(1, int.MaxValue, ErrorMessage = "ID narudžbe mora biti validan")]
        public int OrderID { get; set; }
        
        [Required(ErrorMessage = "Količina je obavezna")]
        [Range(1, int.MaxValue, ErrorMessage = "Količina mora biti najmanje 1")]
        public int Quantity { get; set; }
        
        [Required(ErrorMessage = "Cijena je obavezna")]
        [Range(0.01, float.MaxValue, ErrorMessage = "Cijena mora biti veća od 0")]
        public float Price { get; set; }
        
        [Range(0, 100, ErrorMessage = "Popust mora biti između 0 i 100")]
        public decimal? Discount { get; set; }
    }
}
