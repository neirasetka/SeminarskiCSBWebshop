namespace CBSWebshopSeminarski.Model.Requests
{
    public class OrderUpsertRequest
    {
        public int OrderID { get; set; }
        public string OrderNumber { get; set; }
        public DateTime Date { get; set; }
        public float Price { get; set; }
        public int UserID { get; set; }
        public List<OrderItemUpsertRequest> items { get; set; } = new List<OrderItemUpsertRequest>();
        public string? TrackingNumber { get; set; }
        public string? CarrierCode { get; set; }
        public DateTime? EstimatedDeliveryDate { get; set; }
    }
}
