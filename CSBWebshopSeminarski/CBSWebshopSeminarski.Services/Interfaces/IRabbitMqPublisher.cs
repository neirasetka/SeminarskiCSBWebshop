namespace CBSWebshopSeminarski.Services.Interfaces
{
    public interface IRabbitMqPublisher
    {
        Task PublishAsync(string message, string? routingKey = null, CancellationToken cancellationToken = default);
    }
}