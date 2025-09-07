using System.ComponentModel.DataAnnotations;

namespace CSBWebshopSeminarski.Core.Entities
{
    public class LookbookItems
    {
        [Key]
        public int LookbookItemID { get; set; }
        public string? Title { get; set; }
        public string? Caption { get; set; }
        public string? Tags { get; set; }
        public int? SortOrder { get; set; }
        public bool IsFeatured { get; set; }
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
        public byte[]? Image { get; set; }
        public int? BagID { get; set; }
        public Bags? Bag { get; set; }
        public int? BeltID { get; set; }
        public Belts? Belt { get; set; }
        public OccasionType? Occasion { get; set; }
        public StyleType? Style { get; set; }
        public SeasonType? Season { get; set; }
    }
}
