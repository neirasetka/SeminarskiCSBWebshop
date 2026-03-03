using System.ComponentModel.DataAnnotations;

namespace CSBWebshopSeminarski.Core.Entities
{
    public class Belts
    {
        public Belts()
        {
            Reviews = new HashSet<Reviews>();
            Favorites = new HashSet<Favorites>();
            Rates = new HashSet<Rates>();
        }

        [Key]
        public int BeltID { get; set; }
        public string BeltName { get; set; } = null!;
        public int BeltTypeID { get; set; }
        public string Description { get; set; } = null!;
        public string Code { get; set; } = null!;
        public float Price { get; set; }
        public byte[] Image { get; set; } = null!;
        public int UserID { get; set; }
        public Users User { get; set; } = null!;
        public virtual ICollection<Reviews> Reviews { get; set; } = null!;
        public virtual ICollection<Favorites> Favorites { get; set; } = null!;
        public ICollection<Rates> Rates { get; set; } = null!;
        public virtual BeltTypes BeltType { get; set; } = null!;
    }
}
