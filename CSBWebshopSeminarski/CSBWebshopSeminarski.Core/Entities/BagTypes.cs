using System.ComponentModel.DataAnnotations;

namespace CSBWebshopSeminarski.Core.Entities
{
    public class BagTypes
    {
        [Key]
        public int BagTypeID { get; set; }
        public string BagName { get; set; }
    }
}
