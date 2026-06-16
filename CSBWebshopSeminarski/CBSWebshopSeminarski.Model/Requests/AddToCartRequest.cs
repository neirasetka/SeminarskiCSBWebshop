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

        [Required(ErrorMessage = ValidationMessages.OrderIdRequired)]
        [Range(1, int.MaxValue, ErrorMessage = ValidationMessages.OrderIdValid)]
        public int OrderID { get; set; }

        [Required(ErrorMessage = ValidationMessages.QuantityRequired)]
        [Range(1, int.MaxValue, ErrorMessage = ValidationMessages.QuantityMin)]
        public int Quantity { get; set; }

        public IEnumerable<ValidationResult> Validate(ValidationContext validationContext)
        {
            foreach (var result in BagOrBeltReferenceValidation.ValidateExactlyOne(BagID, BeltID, "Stavka narudžbe"))
            {
                yield return result;
            }
        }
    }
}
