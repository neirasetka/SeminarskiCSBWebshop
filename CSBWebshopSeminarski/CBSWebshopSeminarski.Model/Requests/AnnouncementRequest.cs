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
        [Required(ErrorMessage = "Naslov je obavezan")]
        [MinLength(2, ErrorMessage = "Naslov mora imati najmanje 2 znaka")]
        public string? Subject { get; set; }
        
        [Required(ErrorMessage = "Sadržaj poruke je obavezan")]
        [MinLength(10, ErrorMessage = "Sadržaj poruke mora imati najmanje 10 znakova")]
        public string? Body { get; set; }
        
        public string? TemplateKey { get; set; }
        public Dictionary<string, string>? Variables { get; set; }
        public AnnouncementSegment Segment { get; set; } = AnnouncementSegment.AllSubscribers;
        public DateTime? LaunchDate { get; set; }
        public string? ProductName { get; set; }
        
        [Range(0.01, double.MaxValue, ErrorMessage = "Cijena mora biti veća od 0")]
        public decimal? Price { get; set; }
        
        public string? Color { get; set; }
    }
}
