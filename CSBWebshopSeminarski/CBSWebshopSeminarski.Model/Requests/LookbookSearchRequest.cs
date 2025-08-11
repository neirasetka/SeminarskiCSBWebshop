namespace CBSWebshopSeminarski.Model.Requests
{
    public class LookbookSearchRequest
    {
        public int? BagID { get; set; }
        public int? BeltID { get; set; }
        public bool? IsFeatured { get; set; }
        public string? Tag { get; set; }
        public string? Title { get; set; }
    }
}