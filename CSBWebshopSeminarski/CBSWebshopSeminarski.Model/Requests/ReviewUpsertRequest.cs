using System.ComponentModel.DataAnnotations;
using CBSWebshopSeminarski.Model.Models;

namespace CBSWebshopSeminarski.Model.Requests
{
    public class ReviewUpsertRequest
    {
        [Required(ErrorMessage = "ID korisnika je obavezan")]
        [Range(1, int.MaxValue, ErrorMessage = "ID korisnika mora biti validan")]
        public int UserID { get; set; }
        
        public int BagID { get; set; }
        public int BeltID { get; set; }
        
        [Required(ErrorMessage = "Komentar je obavezan")]
        [MinLength(3, ErrorMessage = "Komentar mora imati najmanje 3 znaka")]
        [MaxLength(1000, ErrorMessage = "Komentar može imati najviše 1000 znakova")]
        public string Comment { get; set; }
        
        public User Users { get; set; }
        
        [Required(ErrorMessage = "Datum je obavezan")]
        public DateTime Date { get; set; }
    }
}
