namespace CBSWebshopSeminarski.Model.Requests
{
    /// <summary>Image is sent as base64 string from the client.</summary>
    public class OutfitIdeaImageUpsertRequest
    {
        public int OutfitIdeaID { get; set; }
        
        /// <summary>Base64-encoded image data (e.g. from JSON).</summary>
        public string Image { get; set; } = string.Empty;
        
        public string? Caption { get; set; }
        
        public int DisplayOrder { get; set; }
    }
}
