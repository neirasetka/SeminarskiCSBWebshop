using CBSWebshopSeminarski.Model.Models;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace CBSWebshopSeminarski.Model.ViewModels
{
    public class PurchasesVM
    {
        public int PurchaseID { get; set; }
        public int UserID { get; set; }
        public int OrderID { get; set; }
        public DateTime PurchaseDate { get; set; }
        public float Price { get; set; }
        public string UserName { get; set; }
        public string BagName { get; set; }
        public string BeltName { get; set; }
        public virtual User User { get; set; }
        public virtual Order Order { get; set; }
    }
}
