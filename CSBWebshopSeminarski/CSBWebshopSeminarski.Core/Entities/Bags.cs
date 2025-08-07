using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace CSBWebshopSeminarski.Core.Entities
{
    public class Bags
    {
        public Bags()
        {
            Reviews = new HashSet<Reviews>();
        }

        [Key]
        public int? BagID { get; set; }
        public string BagName { get; set; }
        public int? BagTypeID { get; set; }
        public string Description { get; set; }
        public string Code { get; set; }
        public float Price { get; set; }
        public byte[] Image { get; set; }
        public string? StateMachine { get; set; }
        public int? UserID { get; set; }
        public Users User { get; set; }
        public virtual ICollection<Reviews> Reviews { get; set; }
        public virtual ICollection<Favorites> Favorites { get; set; }
        public ICollection<Rates> Rate { get; set; }
        public virtual BagTypes BagType { get; set; }
    }
}
