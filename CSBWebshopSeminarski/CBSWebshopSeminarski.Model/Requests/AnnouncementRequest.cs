using System.ComponentModel.DataAnnotations;
using CBSWebshopSeminarski.Model;

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
        [Required(ErrorMessage = ValidationMessages.TitleRequired)]
        [MinLength(2, ErrorMessage = ValidationMessages.TitleMinLength)]
        public string? Subject { get; set; }

        [Required(ErrorMessage = ValidationMessages.MessageContentRequired)]
        [MinLength(10, ErrorMessage = ValidationMessages.MessageContentMinLength)]
        public string? Body { get; set; }

        public string? TemplateKey { get; set; }
        public Dictionary<string, string>? Variables { get; set; }
        public AnnouncementSegment Segment { get; set; } = AnnouncementSegment.AllSubscribers;
        public DateTime? LaunchDate { get; set; }
        public string? ProductName { get; set; }

        [Range(typeof(decimal), "0.01", "79228162514264337593543950335", ErrorMessage = ValidationMessages.PriceGreaterThanZero)]
        public decimal? Price { get; set; }

        public string? Color { get; set; }
    }
}
