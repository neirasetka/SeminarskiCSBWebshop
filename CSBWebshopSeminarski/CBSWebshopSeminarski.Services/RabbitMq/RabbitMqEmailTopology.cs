using Microsoft.Extensions.Configuration;
using RabbitMQ.Client;

namespace CBSWebshopSeminarski.Services.RabbitMq;

public static class RabbitMqEmailTopology
{
    public static void Declare(IModel channel, IConfiguration configuration)
    {
        var topology = RabbitMqConnectionSettings.ReadTopology(configuration);

        channel.ExchangeDeclare(
            topology.DeadLetterExchange,
            ExchangeType.Direct,
            durable: true,
            autoDelete: false);
        channel.QueueDeclare(
            topology.DeadLetterQueueName,
            durable: true,
            exclusive: false,
            autoDelete: false,
            arguments: null);
        channel.QueueBind(
            topology.DeadLetterQueueName,
            topology.DeadLetterExchange,
            topology.DeadLetterRoutingKey,
            arguments: null);

        var queueArgs = new Dictionary<string, object>
        {
            { "x-dead-letter-exchange", topology.DeadLetterExchange },
            { "x-dead-letter-routing-key", topology.DeadLetterRoutingKey }
        };

        channel.ExchangeDeclare(topology.Exchange, ExchangeType.Direct, durable: true, autoDelete: false);
        channel.QueueDeclare(
            topology.QueueName,
            durable: true,
            exclusive: false,
            autoDelete: false,
            arguments: queueArgs);
        channel.QueueBind(topology.QueueName, topology.Exchange, topology.RoutingKey, arguments: null);
    }
}
