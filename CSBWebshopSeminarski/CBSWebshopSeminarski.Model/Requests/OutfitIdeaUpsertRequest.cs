using System.ComponentModel.DataAnnotations;

namespace CBSWebshopSeminarski.Model.Requests
{
    public class OutfitIdeaUpsertRequest
    {
        [Range(1, int.MaxValue, ErrorMessage = "ID torbice mora biti validan")]
        public int BagID { get; set; }
        
        [Required(ErrorMessage = "ID korisnika je obavezan")]
        [Range(1, int.MaxValue, ErrorMessage = "ID korisnika mora biti validan")]
        public int UserID { get; set; }
        
        [Required(ErrorMessage = "Naslov je obavezan")]
        [MinLength(2, ErrorMessage = "Naslov mora imati najmanje 2 znaka")]
        [MaxLength(200, ErrorMessage = "Naslov može imati najviše 200 znakova")]
        public string? Title { get; set; }
        
        [MaxLength(1000, ErrorMessage = "Opis može imati najviše 1000 znakova")]
        public string? Description { get; set; }
    }
}
