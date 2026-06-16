using System.ComponentModel.DataAnnotations;
using CBSWebshopSeminarski.Model;

namespace CBSWebshopSeminarski.Model.Requests
{
    public class LookbookUpsertRequest
    {
        [Required(ErrorMessage = ValidationMessages.TitleRequired)]
        [MinLength(2, ErrorMessage = ValidationMessages.TitleMinLength)]
        [MaxLength(200, ErrorMessage = ValidationMessages.TitleMaxLength)]
        public string? Title { get; set; }

        [MaxLength(500, ErrorMessage = ValidationMessages.CaptionMaxLength500)]
        public string? Caption { get; set; }

        [MaxLength(300, ErrorMessage = ValidationMessages.TagsMaxLength)]
        public string? Tags { get; set; }

        [Range(1, int.MaxValue, ErrorMessage = ValidationMessages.DisplayOrderPositive)]
        public int? SortOrder { get; set; }

        public bool IsFeatured { get; set; }
        public byte[]? Image { get; set; }
        public int? BagID { get; set; }
        public int? BeltID { get; set; }
        public CBSWebshopSeminarski.Model.Models.OccasionType? Occasion { get; set; }
        public CBSWebshopSeminarski.Model.Models.StyleType? Style { get; set; }
        public CBSWebshopSeminarski.Model.Models.SeasonType? Season { get; set; }
    }
}
