using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace CSBWebshopSeminarski.Core.Entities
{
    public class BeltTypes
    {
        [Key]
        public int BeltTypeID { get; set; }
        public string BeltName { get; set; }
    }
}
