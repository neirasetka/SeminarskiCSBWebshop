using System.ComponentModel.DataAnnotations;
using CBSWebshopSeminarski.Model;

namespace CBSWebshopSeminarski.Model.Requests
{
    public class BeltTypeUpsertRequest
    {
        [Required(ErrorMessage = ValidationMessages.BeltTypeNameRequired)]
        [MinLength(2, ErrorMessage = ValidationMessages.BeltTypeNameMinLength)]
        [MaxLength(100, ErrorMessage = ValidationMessages.BeltTypeNameMaxLength)]
        public string BeltName { get; set; } = null!;
    }
}
