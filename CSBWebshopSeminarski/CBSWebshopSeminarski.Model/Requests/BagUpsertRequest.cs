using System.ComponentModel.DataAnnotations;

namespace CBSWebshopSeminarski.Model.Requests
{
    public class BagUpsertRequest
    {
        [Required]
        public string BagName { get; set; } = null!;
        [Required]
        public string Code { get; set; } = null!;
        [Required]
        public float Price { get; set; }
        public string Description { get; set; } = null!;
        public int BagTypeID { get; set; }
        /// <summary>Base64-encoded image data (e.g. from JSON).</summary>
        public string Image { get; set; } = null!;
        public int UserID { get; set; }
    }
}
