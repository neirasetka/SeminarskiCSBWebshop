using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace CSBWebshopSeminarski.Core.Entities
{
    public class BagTypes
    {
        [Key]
        public int BagTypeID { get; set; }
        public string BagName { get; set; }
    }
}
