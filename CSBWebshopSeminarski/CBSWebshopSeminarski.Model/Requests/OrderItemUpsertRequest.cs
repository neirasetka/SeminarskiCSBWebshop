using System.ComponentModel.DataAnnotations;
using CBSWebshopSeminarski.Model;

namespace CBSWebshopSeminarski.Model.Requests
{
    public class OrderItemUpsertRequest : IValidatableObject
    {
        public int? BagID { get; set; }
        public int? BeltID { get; set; }

        [Required(ErrorMessage = ValidationMessages.OrderIdRequired)]
        [Range(1, int.MaxValue, ErrorMessage = ValidationMessages.OrderIdValid)]
        public int OrderID { get; set; }

        [Required(ErrorMessage = ValidationMessages.QuantityRequired)]
        [Range(1, int.MaxValue, ErrorMessage = ValidationMessages.QuantityMin)]
        public int Quantity { get; set; }

        /// <summary>
        /// Admin može ručno postaviti cijenu. Buyer koristi <see cref="AddToCartRequest"/> bez cijene;
        /// servis tada dohvaća cijenu iz kataloga.
        /// </summary>
        [Range(typeof(decimal), "0.01", "100000000", ErrorMessage = ValidationMessages.PriceGreaterThanZero)]
        public decimal? Price { get; set; }

        [Range(typeof(decimal), "0", "100", ErrorMessage = ValidationMessages.DiscountRange)]
        public decimal? Discount { get; set; }

        public IEnumerable<ValidationResult> Validate(ValidationContext validationContext)
        {
            foreach (var result in BagOrBeltReferenceValidation.ValidateExactlyOne(BagID, BeltID, "Stavka narudžbe"))
            {
                yield return result;
            }
        }
    }
}
