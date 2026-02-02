using System.ComponentModel.DataAnnotations;

namespace CBSWebshopSeminarski.Model.Requests
{
    public enum AnnouncementSegment
    {
        GiveawaySubscribers,
        NewCollectionSubscribers,
        AllSubscribers
    }

    public class AnnouncementRequest
    {
        [Required(ErrorMessage = "Title is required.")]
        [MinLength(2, ErrorMessage = "Title must be at least 2 characters long.")]
        public string? Subject { get; set; }
        
        [Required(ErrorMessage = "Message content is required.")]
        [MinLength(10, ErrorMessage = "Message content must be at least 10 characters long.")]
        public string? Body { get; set; }
        
        public string? TemplateKey { get; set; }
        public Dictionary<string, string>? Variables { get; set; }
        public AnnouncementSegment Segment { get; set; } = AnnouncementSegment.AllSubscribers;
        public DateTime? LaunchDate { get; set; }
        public string? ProductName { get; set; }
        
        [Range(0.01, double.MaxValue, ErrorMessage = "Price must be greater than 0.")]
        public decimal? Price { get; set; }
        
        public string? Color { get; set; }
    }
}
