using System.ComponentModel.DataAnnotations;
using CBSWebshopSeminarski.Model.Models;

namespace CBSWebshopSeminarski.Model.Requests
{
    public class ReviewUpsertRequest
    {
        [Required(ErrorMessage = "User ID is required.")]
        [Range(1, int.MaxValue, ErrorMessage = "User ID must be valid.")]
        public int UserID { get; set; }
        
        public int BagID { get; set; }
        public int BeltID { get; set; }
        
        [Required(ErrorMessage = "Comment is required.")]
        [MinLength(3, ErrorMessage = "Comment must be at least 3 characters long.")]
        [MaxLength(1000, ErrorMessage = "A comment can have a maximum of 1000 characters.")]
        public string Comment { get; set; } = null!;
        
        public User Users { get; set; } = null!;
        
        [Required(ErrorMessage = "Date is required.")]
        public DateTime Date { get; set; }
    }
}
