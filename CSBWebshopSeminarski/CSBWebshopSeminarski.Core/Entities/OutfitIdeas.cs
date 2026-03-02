using System.ComponentModel.DataAnnotations;

namespace CSBWebshopSeminarski.Core.Entities
{
    public class OutfitIdeas
    {
        public OutfitIdeas()
        {
            Images = new HashSet<OutfitIdeaImages>();
        }

        [Key]
        public int OutfitIdeaID { get; set; }
        
        public int? BagID { get; set; }
        
        public int? BeltID { get; set; }
        
        public int UserID { get; set; }
        
        public string? Title { get; set; }
        
        public string? Description { get; set; }
        
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
        
        public DateTime? UpdatedAt { get; set; }

        public virtual Bags? Bag { get; set; }
        
        public virtual Belts? Belt { get; set; }
        
        public virtual Users User { get; set; }
        
        public virtual ICollection<OutfitIdeaImages> Images { get; set; }
    }
}
