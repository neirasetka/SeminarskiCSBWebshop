using System.ComponentModel.DataAnnotations;

namespace CSBWebshopSeminarski.Core.Entities
{
    public class OutfitIdeaImages
    {
        [Key]
        public int OutfitIdeaImageID { get; set; }
        
        public int OutfitIdeaID { get; set; }
        
        /// <summary>
        /// Image stored as byte array
        /// </summary>
        public byte[] Image { get; set; }
        
        /// <summary>
        /// Optional caption for the image
        /// </summary>
        public string? Caption { get; set; }
        
        /// <summary>
        /// Display order of the image
        /// </summary>
        public int DisplayOrder { get; set; }
        
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

        public virtual OutfitIdeas OutfitIdea { get; set; }
    }
}
