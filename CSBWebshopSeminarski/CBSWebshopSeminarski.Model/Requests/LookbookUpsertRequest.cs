using System.ComponentModel.DataAnnotations;

namespace CBSWebshopSeminarski.Model.Requests
{
    public class LookbookUpsertRequest
    {
        [Required(ErrorMessage = "Naslov je obavezan")]
        [MinLength(2, ErrorMessage = "Naslov mora imati najmanje 2 znaka")]
        [MaxLength(200, ErrorMessage = "Naslov može imati najviše 200 znakova")]
        public string? Title { get; set; }
        
        [MaxLength(500, ErrorMessage = "Caption može imati najviše 500 znakova")]
        public string? Caption { get; set; }
        
        [MaxLength(300, ErrorMessage = "Tagovi mogu imati najviše 300 znakova")]
        public string? Tags { get; set; }
        
        [Range(0, int.MaxValue, ErrorMessage = "Redoslijed mora biti pozitivan broj")]
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
