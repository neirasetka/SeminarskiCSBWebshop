using System.ComponentModel.DataAnnotations;

namespace CBSWebshopSeminarski.Model.Requests
{
    public class BagTypeUpsertRequest
    {
        [Required(ErrorMessage = "Bag type name is required.")]
        [MinLength(2, ErrorMessage = "Bag type name must have at least 2 characters.")]
        [MaxLength(100, ErrorMessage = "Bag type name can be up to 100 characters.")]
        public string BagName { get; set; } = null!;
    }
}
