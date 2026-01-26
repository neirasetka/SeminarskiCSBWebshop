namespace CBSWebshopSeminarski.Model.Requests
{
    public class OutfitIdeaUpsertRequest
    {
        public int BagID { get; set; }
        
        public int UserID { get; set; }
        
        public string? Title { get; set; }
        
        public string? Description { get; set; }
    }
}
