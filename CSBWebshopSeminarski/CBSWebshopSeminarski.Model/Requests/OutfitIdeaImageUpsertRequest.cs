using System.ComponentModel.DataAnnotations;

namespace CBSWebshopSeminarski.Model.Requests
{
    /// <summary>Image is sent as base64 string from the client.</summary>
    public class OutfitIdeaImageUpsertRequest
    {
        [Range(1, int.MaxValue, ErrorMessage = "Outfit idea ID must be valid.")]
        public int OutfitIdeaID { get; set; }

        [Required(ErrorMessage = "Image is required.")]
        [MinLength(1, ErrorMessage = "Image data cannot be empty.")]
        public string Image { get; set; } = string.Empty;

        [MaxLength(500, ErrorMessage = "Caption can have a maximum of 500 characters.")]
        public string? Caption { get; set; }

        [Range(0, int.MaxValue, ErrorMessage = "Display order must be zero or greater.")]
        public int DisplayOrder { get; set; }
    }
}
