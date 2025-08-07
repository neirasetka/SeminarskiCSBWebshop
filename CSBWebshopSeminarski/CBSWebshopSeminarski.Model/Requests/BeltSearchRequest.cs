using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace CBSWebshopSeminarski.Model.Requests
{
    public class BeltSearchRequest
    {
        public int UserID { get; set; }
        public int? BeltTypeID { get; set; }
        public string BeltName { get; set; }
    }
}
