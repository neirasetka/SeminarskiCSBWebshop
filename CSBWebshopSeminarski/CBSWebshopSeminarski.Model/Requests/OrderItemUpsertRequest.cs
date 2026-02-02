using System.ComponentModel.DataAnnotations;

namespace CBSWebshopSeminarski.Model.Requests
{
    public class OrderItemUpsertRequest
    {
        public int? BagID { get; set; }
        public int? BeltID { get; set; }
        
        [Required(ErrorMessage = "Order ID is required.")]
        [Range(1, int.MaxValue, ErrorMessage = "Order ID must be valid.")]
        public int OrderID { get; set; }
        
        [Required(ErrorMessage = "Quantity is required.")]
        [Range(1, int.MaxValue, ErrorMessage = "Quantity must be at least 1.")]
        public int Quantity { get; set; }
        
        [Required(ErrorMessage = "Price is required.")]
        [Range(0.01, float.MaxValue, ErrorMessage = "Price must be greater than 0.")]
        public float Price { get; set; }
        
        [Range(0, 100, ErrorMessage = "Discount must be between 0 and 100.")]
        public decimal? Discount { get; set; }
    }
}
