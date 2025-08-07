using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace CBSWebshopSeminarski.Model.Models
{
    public class Purchase
    {
        public int PurchaseID { get; set; }
        public int UserID { get; set; }
        public int OrderID { get; set; }
        public DateTime PurchaseDate { get; set; }
        public float Price { get; set; }
        public string UserName { get; set; }
        public string OrderNumber { get; set; }
        public virtual User User { get; set; }
        public virtual Order Order { get; set; }
        public string StripeId { get; set; }
    }
}
