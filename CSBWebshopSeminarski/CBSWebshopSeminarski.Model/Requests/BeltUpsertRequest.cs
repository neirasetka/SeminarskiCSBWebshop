using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace CBSWebshopSeminarski.Model.Requests
{
    public class BeltUpsertRequest
    {
        [Required]
        public string BeltName { get; set; }
        [Required]
        public string Code { get; set; }
        [Required]
        public float Price { get; set; }
        public string Description { get; set; }
        public int BeltTypeID { get; set; }
        public byte[] Image { get; set; }
        public int UserID { get; set; }
    }
}
