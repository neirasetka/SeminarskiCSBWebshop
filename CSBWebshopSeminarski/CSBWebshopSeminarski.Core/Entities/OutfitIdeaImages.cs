using System.ComponentModel.DataAnnotations;

namespace CSBWebshopSeminarski.Core.Entities
{
    public class OutfitIdeaImages
    {
        [Key]
        public int OutfitIdeaImageID { get; set; }
        
        public int OutfitIdeaID { get; set; }
        
        /// Image stored as byte array
        public byte[] Image { get; set; }
        
        /// Optional caption for the image
        public string? Caption { get; set; }
        
        /// Display order of the image
        public int DisplayOrder { get; set; }
        
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

        public virtual OutfitIdeas OutfitIdea { get; set; }
    }
}
