using System.ComponentModel.DataAnnotations;

namespace CSBWebshopSeminarski.Core.Entities
{
    public class BeltTypes
    {
        [Key]
        public int BeltTypeID { get; set; }
        public string BeltName { get; set; } = null!;
    }
}
