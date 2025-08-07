using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace CBSWebshopSeminarski.Model.Requests
{
    public class OrderItemUpsertRequest
    {
        public int? BagID { get; set; }
        public int? BeltID { get; set; }
        public int OrderID { get; set; }
        public int Quantity { get; set; }
        public float Price { get; set; }
        public decimal? Discount { get; set; }
    }
}
