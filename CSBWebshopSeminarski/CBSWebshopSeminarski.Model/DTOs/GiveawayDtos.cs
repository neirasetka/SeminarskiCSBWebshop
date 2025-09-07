namespace CBSWebshopSeminarski.Model.DTOs
{
    public class GiveawayDto
    {
        public int Id { get; set; }
        public string Title { get; set; } = string.Empty;
        public DateTime StartDate { get; set; }
        public DateTime EndDate { get; set; }
        public bool IsClosed { get; set; }
        public int? WinnerParticipantId { get; set; }
    }

    public class ParticipantDto
    {
        public int Id { get; set; }
        public string? Name { get; set; }
        public string? Email { get; set; }
        public DateTime EntryDate { get; set; }
        public int GiveawayId { get; set; }
    }

    public class ParticipantPublicDto
    {
        public int Id { get; set; }
        public string? Name { get; set; }
        public string MaskedEmail { get; set; } = string.Empty;
        public DateTime EntryDate { get; set; }
        public int GiveawayId { get; set; }
    }
}
