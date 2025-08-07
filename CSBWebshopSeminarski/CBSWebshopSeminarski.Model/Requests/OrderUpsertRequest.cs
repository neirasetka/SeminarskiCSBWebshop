using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace CBSWebshopSeminarski.Model.Requests
{
    public class OrderUpsertRequest
    {
        public int OrderID { get; set; }
        public string OrderNumber { get; set; }
        public DateTime Date { get; set; }
        public float Price { get; set; }
        public int UserID { get; set; }
        public List<OrderItemUpsertRequest> items { get; set; } = new List<OrderItemUpsertRequest>();
    }
}
