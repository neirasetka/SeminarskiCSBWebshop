using CBSWebshopSeminarski.Model.Models;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace CBSWebshopSeminarski.Model.ViewModels
{
    public class BeltsListVM
    {
        public int BeltID { get; set; }
        public string BeltName { get; set; }
        public string Code { get; set; }
        public float Price { get; set; }
        public string Description { get; set; }
        public byte[] Image { get; set; }
        public int BeltTypeID { get; set; }
        public BeltType BeltType { get; set; }
    }
}
