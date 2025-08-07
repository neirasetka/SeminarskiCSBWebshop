using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace CSBWebshopSeminarski.Core.Entities
{
    public class Subscribers
    {
        public int Id { get; set; }
        public string Email { get; set; }
        public bool IsSubscribedToGiveaway { get; set; }
        public bool IsSubscribedToNewCollections { get; set; }
    }
}
