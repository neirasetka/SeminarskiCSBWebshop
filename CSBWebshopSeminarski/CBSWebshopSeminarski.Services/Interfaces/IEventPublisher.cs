namespace CBSWebshopSeminarski.Services.Interfaces
{
    public interface IEventPublisher
    {
        Task PublishAsync<T>(string routingKey, T message, CancellationToken cancellationToken = default);
    }
}
