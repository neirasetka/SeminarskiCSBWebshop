using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace CBSWebshopSeminarski.Model.Requests
{
    public class BeltTypeUpsertRequest
    {
        [Required]
        public string BeltName { get; set; }
    }
}
