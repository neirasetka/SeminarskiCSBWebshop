namespace CSBWebshopSeminarski.Core.Exceptions
{
    /// <summary>
    /// The same email is already registered as a participant for this giveaway.
    /// </summary>
    public class AlreadyRegisteredForGiveawayException : Exception
    {
        public AlreadyRegisteredForGiveawayException()
            : base("Već učestvujete u giveawayu.")
        {
        }
    }
}
