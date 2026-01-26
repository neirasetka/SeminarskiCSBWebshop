namespace CBSWebshopSeminarski.Model.Requests
{
    public class OutfitIdeaImageUpsertRequest
    {
        public int OutfitIdeaID { get; set; }
        
        public byte[] Image { get; set; }
        
        public string? Caption { get; set; }
        
        public int DisplayOrder { get; set; }
    }
}
