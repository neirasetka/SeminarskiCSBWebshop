using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace CBSWebshopSeminarski.Model.Requests
{
    public class TransactionSearchRequest
    {
        public int UserID { get; set; }
        public int OrderID { get; set; }
        public DateTime? From { get; set; }
        public DateTime? To { get; set; }
        public string OrderNumber { get; set; }
    }
}
