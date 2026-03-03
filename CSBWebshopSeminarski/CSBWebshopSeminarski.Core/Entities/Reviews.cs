using System.ComponentModel.DataAnnotations;

namespace CSBWebshopSeminarski.Core.Entities
{
    public class Reviews
    {
        [Key]
        public int ReviewID { get; set; }
        public DateTime Date { get; set; }
        public string Comment { get; set; } = null!;
        public int UserID { get; set; }
        public int BagID { get; set; }
        public int BeltID { get; set; }
        public ReviewStatus Status { get; set; }
        public virtual Users User { get; set; } = null!;
        public virtual Bags Bag { get; set; } = null!;
        public virtual Belts Belt { get; set; } = null!;
    }
}
