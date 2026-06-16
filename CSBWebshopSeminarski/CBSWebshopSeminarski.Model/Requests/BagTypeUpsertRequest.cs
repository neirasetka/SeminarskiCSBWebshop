using System.ComponentModel.DataAnnotations;
using CBSWebshopSeminarski.Model;

namespace CBSWebshopSeminarski.Model.Requests
{
    public class BagTypeUpsertRequest
    {
        [Required(ErrorMessage = ValidationMessages.BagTypeNameRequired)]
        [MinLength(2, ErrorMessage = ValidationMessages.BagTypeNameMinLength)]
        [MaxLength(100, ErrorMessage = ValidationMessages.BagTypeNameMaxLength)]
        public string BagName { get; set; } = null!;
    }
}
