using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace CBSWebshopSeminarski.Model.Requests
{
    public class BagSearchRequest
    {
        public int UserID { get; set; }
        public int? BagTypeID { get; set; }
        public string BagName { get; set; }
    }
}
