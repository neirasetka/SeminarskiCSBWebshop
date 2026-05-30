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
        [Range(0.01, 100_000_000, ErrorMessage = "Price must be greater than zero.")]
        public decimal Price { get; set; }
        public string Description { get; set; } = null!;
        public int BagTypeID { get; set; }
        /// <summary>Base64-encoded image data (e.g. from JSON).</summary>
        public string Image { get; set; } = null!;
        public int UserID { get; set; }
    }
}
