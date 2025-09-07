using System.ComponentModel.DataAnnotations;

namespace CSBWebshopSeminarski.Core.Entities
{
    public class Belts
    {
        public Belts()
        {
            Reviews = new HashSet<Reviews>();
        }

        [Key]
        public int BeltID { get; set; }
        public string BeltName { get; set; }
        public int BeltTypeID { get; set; }
        public string Description { get; set; }
        public string Code { get; set; }
        public float Price { get; set; }
        public byte[] Image { get; set; }
        public int UserID { get; set; }
        public Users User { get; set; }
        public virtual ICollection<Reviews> Reviews { get; set; }
        public virtual ICollection<Favorites> Favorites { get; set; }
        public ICollection<Rates> Rates { get; set; }
        public virtual BeltTypes BeltType { get; set; }
    }
}
