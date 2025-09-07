using System.ComponentModel.DataAnnotations;

namespace CBSWebshopSeminarski.Model.Requests
{
    public class BeltTypeUpsertRequest
    {
        [Required]
        public string BeltName { get; set; }
    }
}
