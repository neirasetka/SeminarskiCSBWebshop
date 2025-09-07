namespace CSBWebshopSeminarski.Core.Entities
{
    public class Participants
    {
        public int Id { get; set; }
        public string? Name { get; set; }
        public string? Email { get; set; }
        public DateTime EntryDate { get; set; }
        public int GiveawayId { get; set; }
        public Giveaways? Giveaway { get; set; }
    }
}
