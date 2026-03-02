using System.Text.Json.Serialization;

namespace CBSWebshopSeminarski.Model.Models
{
    public class OutfitIdea
    {
        public int OutfitIdeaID { get; set; }
        
        public int? BagID { get; set; }
        
        public int? BeltID { get; set; }
        
        public int UserID { get; set; }
        
        public string? Title { get; set; }
        
        public string? Description { get; set; }
        
        public DateTime CreatedAt { get; set; }
        
        public DateTime? UpdatedAt { get; set; }

        [JsonIgnore]
        public virtual Bag? Bag { get; set; }
        
        [JsonIgnore]
        public virtual Belt? Belt { get; set; }
        
        [JsonIgnore]
        public virtual User User { get; set; }
        
        public virtual ICollection<OutfitIdeaImage> Images { get; set; }
    }
}
