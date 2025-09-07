namespace CBSWebshopSeminarski.Model.Requests
{
    public class ReportsSearchRequest
    {
        public DateTime? FromDateUtc { get; set; }
        public DateTime? ToDateUtc { get; set; }
        public int? Take { get; set; }
    }
}
