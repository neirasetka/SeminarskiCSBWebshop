using System.ComponentModel.DataAnnotations;

namespace CBSWebshopSeminarski.Model.Requests
{
    public class BeltTypeUpsertRequest
    {
        [Required(ErrorMessage = "Belt type name is required.")]
        [MinLength(2, ErrorMessage = "Belt type name must have at least 2 characters.")]
        [MaxLength(100, ErrorMessage = "Belt type name can be up to 100 characters.")]
        public string BeltName { get; set; } = null!;
    }
}
