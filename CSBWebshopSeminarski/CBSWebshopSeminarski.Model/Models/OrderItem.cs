namespace CBSWebshopSeminarski.Model.Models
{
    public class OrderItem
    {
        public int OrderItemsID { get; set; }
        public int OrderID { get; set; }
        public int BagID { get; set; }
        public int BeltID { get; set; }
        public Bag Bag { get; set; } = null!;
        public Belt Belt { get; set; } = null!;
        public Order Order { get; set; } = null!;
        public int Quantity { get; set; }
        public decimal Price { get; set; }
        public decimal? Discount { get; set; }
        public string Code { get; set; } = null!;
        public string Name { get; set; } = null!;
    }
}
