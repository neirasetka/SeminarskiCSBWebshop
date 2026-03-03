using System.ComponentModel.DataAnnotations;

namespace CSBWebshopSeminarski.Core.Entities
{
    public class Rates
    {
        [Key]
        public int RateID { get; set; }
        public int UserID { get; set; }
        public int BagID { get; set; }
        public int BeltID { get; set; }
        public int Rating { get; set; }
        public virtual Bags Bag { get; set; } = null!;
        public virtual Belts Belt { get; set; } = null!;
        public virtual Users User { get; set; } = null!;
    }
}
