using CBSWebshopSeminarski.Model.Models;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace CBSWebshopSeminarski.Model.ViewModels
{
    public class BagsListVM
    {
        public int BagID { get; set; }
        public string BagName { get; set; }
        public string Code { get; set; }
        public float Price { get; set; }
        public string Description { get; set; }
        public byte[] Image { get; set; }
        public int BagTypeID { get; set; }
        public BagType BagType { get; set; }
    }
}
