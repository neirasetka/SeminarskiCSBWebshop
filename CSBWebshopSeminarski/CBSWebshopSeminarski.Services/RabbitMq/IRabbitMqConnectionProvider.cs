using RabbitMQ.Client;

namespace CBSWebshopSeminarski.Services.RabbitMq;

/// <summary>
/// Dijeljena dugotrajna RabbitMQ konekcija po procesu (reconnect na zahtjev).
/// </summary>
public interface IRabbitMqConnectionProvider : IDisposable
{
    IConnection GetConnection();
}
