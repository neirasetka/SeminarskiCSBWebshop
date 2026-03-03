using System.ComponentModel.DataAnnotations;

namespace CSBWebshopSeminarski.Core.Entities
{
    public class Giveaways
    {
        public int Id { get; set; }
        public string Title { get; set; } = null!;
        public DateTime StartDate { get; set; }
        public DateTime EndDate { get; set; }
        public bool IsClosed { get; set; }
        public int? WinnerParticipantId { get; set; }
        public Participants? WinnerParticipant { get; set; }
        public ICollection<Participants> Participants { get; set; } = new List<Participants>();
        [Timestamp]
        public byte[]? RowVersion { get; set; }
    }
}
