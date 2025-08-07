using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace CBSWebshopSeminarski.Model.Requests
{
    public class UserAuthenticationRequest
    {
        public string UserName { get; set; }
        public string Password { get; set; }
    }
}
