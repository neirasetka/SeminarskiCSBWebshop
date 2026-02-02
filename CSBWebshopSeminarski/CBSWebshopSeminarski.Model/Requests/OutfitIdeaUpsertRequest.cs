using System.ComponentModel.DataAnnotations;

namespace CBSWebshopSeminarski.Model.Requests
{
    public class OutfitIdeaUpsertRequest
    {
        [Range(1, int.MaxValue, ErrorMessage = "Bag ID must be valid.")]
        public int BagID { get; set; }
        
        [Required(ErrorMessage = "User ID is required.")]
        [Range(1, int.MaxValue, ErrorMessage = "User ID must be valid.")]
        public int UserID { get; set; }
        
        [Required(ErrorMessage = "Title is required.")]
        [MinLength(2, ErrorMessage = "Title must be at least 2 characters long.")]
        [MaxLength(200, ErrorMessage = "The title can be a maximum of 200 characters.")]
        public string? Title { get; set; }
        
        [MaxLength(1000, ErrorMessage = "The description can be up to 1000 characters long.")]
        public string? Description { get; set; }
    }
}
