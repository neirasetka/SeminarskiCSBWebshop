using System.ComponentModel.DataAnnotations;

namespace CBSWebshopSeminarski.Model.Requests
{
    public class RateUpsertRequest
    {
        /// <summary>Set by server from JWT; ignored if sent by client.</summary>
        public int UserID { get; set; }
        
        public int BagID { get; set; }
        public int BeltID { get; set; }
        
        [Required(ErrorMessage = "Rating is required.")]
        [Range(1, 5, ErrorMessage = "Rating must be between 1 and 5.")]
        public int Rating { get; set; }
    }
}
