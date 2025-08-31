using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace CSBWebshopSeminarski.Core.Entities
{
    public class Reviews
    {
        [Key]
        public int ReviewID { get; set; }
        public DateTime Date { get; set; }
        public string Comment { get; set; }
        public int UserID { get; set; }
        public int BagID { get; set; }
        public int BeltID { get; set; }
        public ReviewStatus Status { get; set; }
        public virtual Users User { get; set; }
        public virtual Bags Bag { get; set; }
        public virtual Belts Belt { get; set; }
    }
}
