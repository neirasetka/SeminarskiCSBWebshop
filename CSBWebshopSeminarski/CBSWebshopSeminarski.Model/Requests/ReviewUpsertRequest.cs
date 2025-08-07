using CBSWebshopSeminarski.Model.Models;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace CBSWebshopSeminarski.Model.Requests
{
    public class ReviewUpsertRequest
    {
        public int UserID { get; set; }
        public int BagID { get; set; }
        public int BeltID { get; set; }
        public string Comment { get; set; }
        public User Users { get; set; }
        public DateTime Date { get; set; }
    }
}
