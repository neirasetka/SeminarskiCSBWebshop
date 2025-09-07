using System.ComponentModel.DataAnnotations;
namespace CBSWebshopSeminarski.Model.Requests
{
    public class CreateGiveawayRequest
    {
        [Required]
        public string Title { get; set; } = string.Empty;
        public DateTime StartDate { get; set; }
        public DateTime EndDate { get; set; }
    }

    public class RegisterParticipantRequest
    {
        public string Name { get; set; } = string.Empty;
        [Required]
        [EmailAddress]
        public string Email { get; set; } = string.Empty;
    }
}
