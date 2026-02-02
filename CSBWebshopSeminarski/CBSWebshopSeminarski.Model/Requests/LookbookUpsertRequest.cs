using System.ComponentModel.DataAnnotations;

namespace CBSWebshopSeminarski.Model.Requests
{
    public class LookbookUpsertRequest
    {
        [Required(ErrorMessage = "Title is required.")]
        [MinLength(2, ErrorMessage = "Title must be at least 2 characters long.")]
        [MaxLength(200, ErrorMessage = "Title can be up to 200 characters.")]
        public string? Title { get; set; }
        
        [MaxLength(500, ErrorMessage = "Caption can have a maximum of 500 characters.")]
        public string? Caption { get; set; }
        
        [MaxLength(300, ErrorMessage = "Tags can have a maximum of 300 characters.")]
        public string? Tags { get; set; }
        
        [Range(0, int.MaxValue, ErrorMessage = "The order must be a positive number.")]
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
