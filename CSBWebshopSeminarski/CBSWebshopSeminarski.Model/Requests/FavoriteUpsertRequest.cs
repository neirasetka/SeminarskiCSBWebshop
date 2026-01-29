using System.ComponentModel.DataAnnotations;

namespace CBSWebshopSeminarski.Model.Requests
{
    public class FavoriteUpsertRequest
    {
        [Required(ErrorMessage = "ID korisnika je obavezan")]
        [Range(1, int.MaxValue, ErrorMessage = "ID korisnika mora biti validan")]
        public int UserID { get; set; }
        
        public int? BagID { get; set; }
        public int? BeltID { get; set; }
    }
}
