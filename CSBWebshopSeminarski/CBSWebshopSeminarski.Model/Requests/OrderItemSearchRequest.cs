namespace CBSWebshopSeminarski.Model.Requests
{
    public class OrderItemSearchRequest
    {
        public int? OrderItemID { get; set; }
        public int? OrderID { get; set; }
        public int? BagID { get; set; }
        public int? BeltID { get; set; }
    }
}
