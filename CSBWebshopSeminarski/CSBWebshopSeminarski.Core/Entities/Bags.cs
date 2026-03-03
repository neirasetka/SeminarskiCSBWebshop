using System.ComponentModel.DataAnnotations;

namespace CSBWebshopSeminarski.Core.Entities
{
    public class Bags
    {
        public Bags()
        {
            Reviews = new HashSet<Reviews>();
            Favorites = new HashSet<Favorites>();
            Rate = new HashSet<Rates>();
        }

        [Key]
        public int? BagID { get; set; }
        public string BagName { get; set; } = null!;
        public int? BagTypeID { get; set; }
        public string Description { get; set; } = null!;
        public string Code { get; set; } = null!;
        public float Price { get; set; }
        public byte[] Image { get; set; } = null!;
        public string? StateMachine { get; set; }
        public int? UserID { get; set; }
        public Users User { get; set; } = null!;
        public virtual ICollection<Reviews> Reviews { get; set; } = null!;
        public virtual ICollection<Favorites> Favorites { get; set; } = null!;
        public ICollection<Rates> Rate { get; set; } = null!;
        public virtual BagTypes BagType { get; set; } = null!;
    }
}
