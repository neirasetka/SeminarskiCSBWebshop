using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace CBSWebshopSeminarski.Model.Requests
{
    public class FavoriteSearchRequest
    {
        public int UserID { get; set; }
        public int BagID { get; set; }
        public int BeltID { get; set; }
    }
}
