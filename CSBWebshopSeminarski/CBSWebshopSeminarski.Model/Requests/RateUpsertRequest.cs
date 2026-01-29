using System.ComponentModel.DataAnnotations;

namespace CBSWebshopSeminarski.Model.Requests
{
    public class RateUpsertRequest
    {
        [Required(ErrorMessage = "ID korisnika je obavezan")]
        [Range(1, int.MaxValue, ErrorMessage = "ID korisnika mora biti validan")]
        public int UserID { get; set; }
        
        public int BagID { get; set; }
        public int BeltID { get; set; }
        
        [Required(ErrorMessage = "Ocjena je obavezna")]
        [Range(1, 5, ErrorMessage = "Ocjena mora biti između 1 i 5")]
        public int Rating { get; set; }
    }
}
