namespace CBSWebshopSeminarski.Model.Requests
{
    public class BeltSearchRequest
    {
        public int UserID { get; set; }
        public int? BeltTypeID { get; set; }
        public string BeltName { get; set; }
    }
}
