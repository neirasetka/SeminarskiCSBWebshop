using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace CBSWebshopSeminarski.Model.Models
{
    public class Bag
    {
        public int BagID { get; set; }
        public string BagName { get; set; } = "Name";
        public string Code { get; set; } = "Code";
        public float Price { get; set; }
        public string Description { get; set; } = "Description";
        public byte[] Image { get; set; }
        public int BagTypeID { get; set; }
        public BagType BagType { get; set; }
        public int UserID { get; set; }
        public User Users { get; set; }
    }
}
