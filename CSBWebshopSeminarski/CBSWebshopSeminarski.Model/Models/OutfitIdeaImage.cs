namespace CBSWebshopSeminarski.Model.Models
{
    public class OutfitIdeaImage
    {
        public int OutfitIdeaImageID { get; set; }
        
        public int OutfitIdeaID { get; set; }
        
        public byte[] Image { get; set; }
        
        public string? Caption { get; set; }
        
        public int DisplayOrder { get; set; }
        
        public DateTime CreatedAt { get; set; }
    }
}
