namespace CBSWebshopSeminarski.Model.Requests
{
    public class PurchaseSearchRequest
    {
        public DateTime? From { get; set; }
        public DateTime? To { get; set; }
        public int? BagTypeID { get; set; }
        public int? BeltTypeID { get; set; }
        public int BagID { get; set; }
        public int BeltID { get; set; }
        public int OrderID { get; set; }
    }
}
