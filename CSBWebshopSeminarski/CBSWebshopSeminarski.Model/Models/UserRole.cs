using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace CBSWebshopSeminarski.Model.Models
{
    public class UserRole
    {
        public int UserRolesID { get; set; }
        public int UserID { get; set; }
        public int RolesID { get; set; }
        public Role Role { get; set; }
    }
}
