namespace CBSWebshopSeminarski.Services.Interfaces
{
    using RabbitMQ.Client;

    public interface IRabbitMqConnection
    {
        IConnection GetConnection();
    }
}