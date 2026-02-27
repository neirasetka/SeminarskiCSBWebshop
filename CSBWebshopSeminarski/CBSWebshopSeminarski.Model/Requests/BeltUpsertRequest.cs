using System.ComponentModel.DataAnnotations;

namespace CBSWebshopSeminarski.Model.Requests
{
    public class BeltUpsertRequest
    {
        [Required]
        public string BeltName { get; set; }
        [Required]
        public string Code { get; set; }
        [Required]
        public float Price { get; set; }
        public string Description { get; set; }
        public int BeltTypeID { get; set; }
        /// <summary>Base64-encoded image data (e.g. from JSON).</summary>
        public string Image { get; set; }
        public int UserID { get; set; }
    }
}
