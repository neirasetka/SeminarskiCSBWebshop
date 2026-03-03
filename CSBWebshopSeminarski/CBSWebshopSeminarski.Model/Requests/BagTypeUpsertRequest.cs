using System.ComponentModel.DataAnnotations;

namespace CBSWebshopSeminarski.Model.Requests
{
    public class BagTypeUpsertRequest
    {
        [Required]
        public string BagName { get; set; } = null!;
    }
}
