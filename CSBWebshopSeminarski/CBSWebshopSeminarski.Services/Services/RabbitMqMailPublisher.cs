using Microsoft.Extensions.Configuration;
using RabbitMQ.Client;
using System.Collections.Generic;
using System.Text;
using System.Text.Json;

namespace CBSWebshopSeminarski.Services.Services
{
    public class RabbitMqMailPublisher : IDisposable
    {
        private readonly IConfiguration _configuration;
        private readonly string _exchangeName;
        private readonly string _queueName;
        private readonly string _routingKey;
        private readonly string _deadLetterExchange;
        private readonly string _deadLetterQueueName;
        private readonly string _deadLetterRoutingKey;
        private readonly object _lock = new();
        private IConnection? _connection;
        private IModel? _channel;
        private bool _disposed;

        public RabbitMqMailPublisher(IConfiguration configuration)
        {
            _configuration = configuration;
            _exchangeName = _configuration["RabbitMQ:Exchange"] ?? "EmailExchange";
            _queueName = _configuration["RabbitMQ:QueueName"] ?? "EmailQueue";
            _routingKey = _configuration["RabbitMQ:RoutingKey"] ?? "email_queue";
            _deadLetterExchange = _configuration["RabbitMQ:DeadLetterExchange"] ?? "EmailDeadLetterExchange";
            _deadLetterQueueName = _configuration["RabbitMQ:DeadLetterQueueName"] ?? "EmailDeadLetterQueue";
            _deadLetterRoutingKey = _configuration["RabbitMQ:DeadLetterRoutingKey"] ?? "email_dead_letter";
        }

        private void EnsureConnection()
        {
            if (_connection != null && _connection.IsOpen && _channel != null && _channel.IsOpen)
                return;

            _channel?.Dispose();
            _connection?.Dispose();

            var host = Environment.GetEnvironmentVariable("RABBITMQ_HOST")
                ?? _configuration["RabbitMQ:HostName"]
                ?? "localhost";
            var port = int.TryParse(
                Environment.GetEnvironmentVariable("RABBITMQ_PORT") ?? _configuration["RabbitMQ:Port"],
                out var parsedPort)
                ? parsedPort
                : 5672;
            var userName = Environment.GetEnvironmentVariable("RABBITMQ_USERNAME")
                ?? _configuration["RabbitMQ:UserName"]
                ?? "guest";
            var password = Environment.GetEnvironmentVariable("RABBITMQ_PASSWORD")
                ?? _configuration["RabbitMQ:Password"]
                ?? "guest";

            var factory = new ConnectionFactory
            {
                HostName = host,
                Port = port,
                UserName = userName,
                Password = password,
                AutomaticRecoveryEnabled = true,
                NetworkRecoveryInterval = TimeSpan.FromSeconds(10)
            };
            factory.ClientProvidedName = "CSB Mail Producer";

            _connection = factory.CreateConnection();
            _channel = _connection.CreateModel();
            DeclareEmailTopology(_channel);
        }

        private void DeclareEmailTopology(IModel channel)
        {
            channel.ExchangeDeclare(_deadLetterExchange, ExchangeType.Direct, durable: true);
            channel.QueueDeclare(_deadLetterQueueName, durable: true, exclusive: false, autoDelete: false, arguments: null);
            channel.QueueBind(_deadLetterQueueName, _deadLetterExchange, _deadLetterRoutingKey, null);

            var queueArgs = new Dictionary<string, object>
            {
                { "x-dead-letter-exchange", _deadLetterExchange },
                { "x-dead-letter-routing-key", _deadLetterRoutingKey }
            };

            channel.ExchangeDeclare(_exchangeName, ExchangeType.Direct, durable: true);
            channel.QueueDeclare(_queueName, durable: true, exclusive: false, autoDelete: false, arguments: queueArgs);
            channel.QueueBind(_queueName, _exchangeName, _routingKey, null);
        }

        public void Publish(string sender, string recipient, string subject, string content)
        {
            lock (_lock)
            {
                EnsureConnection();

                var payload = new MailQueueMessage
                {
                    Sender = sender,
                    Recipient = recipient,
                    Subject = subject,
                    Content = content
                };

                var message = JsonSerializer.Serialize(payload);
                var body = Encoding.UTF8.GetBytes(message);
                var props = _channel!.CreateBasicProperties();
                props.ContentType = "application/json";
                props.DeliveryMode = 2;

                _channel.BasicPublish(
                    exchange: _exchangeName,
                    routingKey: _routingKey,
                    basicProperties: props,
                    body: body);
            }
        }

        public void Dispose()
        {
            if (_disposed) return;
            _disposed = true;
            _channel?.Dispose();
            _connection?.Dispose();
        }

        private class MailQueueMessage
        {
            public string Sender { get; set; } = string.Empty;
            public string Recipient { get; set; } = string.Empty;
            public string Subject { get; set; } = string.Empty;
            public string Content { get; set; } = string.Empty;
        }
    }
}
