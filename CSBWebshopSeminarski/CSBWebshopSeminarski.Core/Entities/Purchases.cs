using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace CSBWebshopSeminarski.Core.Entities
{
    public class Purchases
    {
        [Key]
        public int PurchaseID { get; set; }
        public int UserID { get; set; }
        public int OrderID { get; set; }
        public DateTime PurchaseDate { get; set; }
        public float Price { get; set; }
        public string Username { get; set; }
        public string OrderNumber { get; set; }
        public virtual Users User { get; set; }
        public virtual Orders Order { get; set; }
        public string StripeId { get; set; }
    }
}
