using Microsoft.Extensions.Configuration;
using RabbitMQ.Client;

namespace CBSWebshopSeminarski.Services.RabbitMq;

public static class RabbitMqConnectionSettings
{
    public static ConnectionFactory CreateFactory(IConfiguration configuration, string clientProvidedName)
    {
        var host = Environment.GetEnvironmentVariable("RABBITMQ_HOST")
            ?? configuration["RabbitMQ:HostName"]
            ?? "localhost";
        var port = int.TryParse(
            Environment.GetEnvironmentVariable("RABBITMQ_PORT") ?? configuration["RabbitMQ:Port"],
            out var parsedPort)
            ? parsedPort
            : 5672;
        var userName = Environment.GetEnvironmentVariable("RABBITMQ_USERNAME")
            ?? configuration["RabbitMQ:UserName"]
            ?? "guest";
        var password = Environment.GetEnvironmentVariable("RABBITMQ_PASSWORD")
            ?? configuration["RabbitMQ:Password"]
            ?? "guest";

        var factory = new ConnectionFactory
        {
            HostName = host,
            Port = port,
            UserName = userName,
            Password = password,
            AutomaticRecoveryEnabled = true,
            NetworkRecoveryInterval = TimeSpan.FromSeconds(10),
            RequestedConnectionTimeout = TimeSpan.FromSeconds(30),
            RequestedHeartbeat = TimeSpan.FromSeconds(60),
            DispatchConsumersAsync = true
        };
        factory.ClientProvidedName = clientProvidedName;
        return factory;
    }

    public static RabbitMqTopologyNames ReadTopology(IConfiguration configuration) =>
        new(
            Exchange: configuration["RabbitMQ:Exchange"] ?? "EmailExchange",
            QueueName: configuration["RabbitMQ:QueueName"] ?? "EmailQueue",
            RoutingKey: configuration["RabbitMQ:RoutingKey"] ?? "email_queue",
            DeadLetterExchange: configuration["RabbitMQ:DeadLetterExchange"] ?? "EmailDeadLetterExchange",
            DeadLetterQueueName: configuration["RabbitMQ:DeadLetterQueueName"] ?? "EmailDeadLetterQueue",
            DeadLetterRoutingKey: configuration["RabbitMQ:DeadLetterRoutingKey"] ?? "email_dead_letter");
}

public sealed record RabbitMqTopologyNames(
    string Exchange,
    string QueueName,
    string RoutingKey,
    string DeadLetterExchange,
    string DeadLetterQueueName,
    string DeadLetterRoutingKey);
