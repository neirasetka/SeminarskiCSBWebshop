using System.ComponentModel.DataAnnotations;
using CBSWebshopSeminarski.Model;

namespace CBSWebshopSeminarski.Model.Requests
{
    /// <summary>Image is sent as base64 string from the client.</summary>
    public class OutfitIdeaImageUpsertRequest
    {
        [Range(1, int.MaxValue, ErrorMessage = ValidationMessages.OutfitIdeaIdValid)]
        public int OutfitIdeaID { get; set; }

        [Required(ErrorMessage = ValidationMessages.ImageRequired)]
        [MinLength(1, ErrorMessage = ValidationMessages.ImageDataNotEmpty)]
        public string Image { get; set; } = string.Empty;

        [MaxLength(500, ErrorMessage = ValidationMessages.CaptionMaxLength500)]
        public string? Caption { get; set; }

        [Range(0, int.MaxValue, ErrorMessage = ValidationMessages.DisplayOrderNonNegative)]
        public int DisplayOrder { get; set; }
    }
}
