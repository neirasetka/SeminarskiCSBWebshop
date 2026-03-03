namespace CSBWebshopSeminarski.Core.Entities
{
    public class Subscribers
    {
        public int Id { get; set; }
        public string Email { get; set; } = null!;
        public bool IsSubscribedToGiveaway { get; set; }
        public bool IsSubscribedToNewCollections { get; set; }
    }
}
