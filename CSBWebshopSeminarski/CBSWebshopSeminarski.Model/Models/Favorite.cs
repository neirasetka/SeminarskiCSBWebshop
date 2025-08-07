using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace CBSWebshopSeminarski.Model.Models
{
    public class Favorite
    {
        public int UserID { get; set; }
        public virtual User User { get; set; }
        public int BagID { get; set; }
        public int BeltID { get; set; }
        public virtual Belt Bag { get; set; }
        public virtual Belt Belt { get; set; }
    }
}
