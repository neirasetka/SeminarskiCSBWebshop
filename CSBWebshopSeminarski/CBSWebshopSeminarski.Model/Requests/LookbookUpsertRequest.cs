namespace CBSWebshopSeminarski.Model.Requests
{
    public class LookbookUpsertRequest
    {
        public string? Title { get; set; }
        public string? Caption { get; set; }
        public string? Tags { get; set; }
        public int? SortOrder { get; set; }
        public bool IsFeatured { get; set; }
        public byte[]? Image { get; set; }
        public int? BagID { get; set; }
        public int? BeltID { get; set; }
        public CBSWebshopSeminarski.Model.Models.OccasionType? Occasion { get; set; }
        public CBSWebshopSeminarski.Model.Models.StyleType? Style { get; set; }
        public CBSWebshopSeminarski.Model.Models.SeasonType? Season { get; set; }
    }
}
