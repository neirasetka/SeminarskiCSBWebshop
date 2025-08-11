namespace CBSWebshopSeminarski.Model.Models
{
    public class LookbookItem
    {
        public int LookbookItemID { get; set; }
        public string? Title { get; set; }
        public string? Caption { get; set; }
        public string? Tags { get; set; }
        public int? SortOrder { get; set; }
        public bool IsFeatured { get; set; }
        public DateTime CreatedAt { get; set; }
        public byte[]? Image { get; set; }
        public int? BagID { get; set; }
        public int? BeltID { get; set; }
        public OccasionType? Occasion { get; set; }
        public StyleType? Style { get; set; }
        public SeasonType? Season { get; set; }
    }
}