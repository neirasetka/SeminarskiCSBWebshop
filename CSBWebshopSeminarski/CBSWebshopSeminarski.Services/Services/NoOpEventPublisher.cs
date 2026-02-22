using CBSWebshopSeminarski.Services.Interfaces;

namespace CBSWebshopSeminarski.Services.Services
{
    /// <summary>
    /// No-op implementation used when RabbitMQ is unavailable so the app can start without it.
    /// </summary>
    public class NoOpEventPublisher : IEventPublisher
    {
        public Task PublishAsync<T>(string routingKey, T message, CancellationToken cancellationToken = default)
            => Task.CompletedTask;
    }
}
