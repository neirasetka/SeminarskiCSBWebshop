using System.ComponentModel.DataAnnotations;
using CBSWebshopSeminarski.Model;

namespace CBSWebshopSeminarski.Model.Requests
{
    public class OrderItemUpsertRequest : IValidatableObject
    {
        public int? BagID { get; set; }
        public int? BeltID { get; set; }
        
        [Required(ErrorMessage = "Order ID is required.")]
        [Range(1, int.MaxValue, ErrorMessage = "Order ID must be valid.")]
        public int OrderID { get; set; }
        
        [Required(ErrorMessage = "Quantity is required.")]
        [Range(1, int.MaxValue, ErrorMessage = "Quantity must be at least 1.")]
        public int Quantity { get; set; }

        /// <summary>
        /// Admin može ručno postaviti cijenu. Buyer koristi <see cref="AddToCartRequest"/> bez cijene;
        /// servis tada dohvaća cijenu iz kataloga.
        /// </summary>
        [Range(typeof(decimal), "0.01", "100000000", ErrorMessage = "Price must be greater than zero.")]
        public decimal? Price { get; set; }

        [Range(typeof(decimal), "0", "100", ErrorMessage = "Discount must be between 0 and 100.")]
        public decimal? Discount { get; set; }

        public IEnumerable<ValidationResult> Validate(ValidationContext validationContext)
        {
            foreach (var result in BagOrBeltReferenceValidation.ValidateExactlyOne(BagID, BeltID, "Order item"))
            {
                yield return result;
            }
        }
    }
}
