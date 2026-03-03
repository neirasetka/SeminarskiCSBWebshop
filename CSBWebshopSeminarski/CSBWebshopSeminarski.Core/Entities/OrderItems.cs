using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace CSBWebshopSeminarski.Core.Entities
{
    public class OrderItems
    {
        [Key]
        public int OrderItemID { get; set; }
        public int OrderID { get; set; }
        public int? BagID { get; set; }
        public int? BeltID { get; set; }
        [Column(TypeName = "decimal(18,2)")]
        public decimal? Discount { get; set; }
        public float? Price { get; set; }
        public int? Quantity { get; set; }
        public virtual Bags? Bag { get; set; }
        public virtual Belts? Belt { get; set; }
        public virtual Orders Order { get; set; }
    }
}
