using System.ComponentModel.DataAnnotations;
using CBSWebshopSeminarski.Model;

namespace CBSWebshopSeminarski.Model.Requests
{
    /// <summary>
    /// Buyer request za dodavanje stavke u korpu — bez cijene i popusta (server uzima cijenu iz kataloga).
    /// Popust i ručna cijena: <see cref="OrderItemUpsertRequest"/> preko Admin CRUD-a.
    /// </summary>
    public class AddToCartRequest : IValidatableObject
    {
        public int? BagID { get; set; }
        public int? BeltID { get; set; }

        [Required(ErrorMessage = "Order ID is required.")]
        [Range(1, int.MaxValue, ErrorMessage = "Order ID must be valid.")]
        public int OrderID { get; set; }

        [Required(ErrorMessage = "Quantity is required.")]
        [Range(1, int.MaxValue, ErrorMessage = "Quantity must be at least 1.")]
        public int Quantity { get; set; }

        public IEnumerable<ValidationResult> Validate(ValidationContext validationContext)
        {
            foreach (var result in BagOrBeltReferenceValidation.ValidateExactlyOne(BagID, BeltID, "Order item"))
            {
                yield return result;
            }
        }
    }
}
