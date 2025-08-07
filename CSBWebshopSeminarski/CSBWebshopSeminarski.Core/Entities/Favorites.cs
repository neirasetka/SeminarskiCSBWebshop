using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace CSBWebshopSeminarski.Core.Entities
{
    public class Favorites
    {
        [Key]
        public int UserID { get; set; }
        public virtual Users User { get; set; }
        public int BagID { get; set; }
        public virtual Bags Bag { get; set; }
        public int BeltID { get; set; }
        public virtual Belts Belt { get; set; }
    }
}
