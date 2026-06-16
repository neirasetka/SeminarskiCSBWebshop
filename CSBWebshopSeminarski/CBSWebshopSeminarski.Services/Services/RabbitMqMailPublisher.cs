using CBSWebshopSeminarski.Services.Exceptions;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using RabbitMQ.Client;
using System.Collections.Generic;
using System.Text;
using System.Text.Json;

namespace CBSWebshopSeminarski.Services.Services
{
    public class RabbitMqMailPublisher : IDisposable
    {
        private readonly IConfiguration _configuration;
        private readonly ILogger<RabbitMqMailPublisher> _logger;
        private readonly string _exchangeName;
        private readonly string _queueName;
        private readonly string _routingKey;
        private readonly string _deadLetterExchange;
        private readonly string _deadLetterQueueName;
        private readonly string _deadLetterRoutingKey;
        private readonly object _sync = new();
        private IConnection? _connection;
        private IModel? _channel;
        private bool _disposed;

        public RabbitMqMailPublisher(IConfiguration configuration, ILogger<RabbitMqMailPublisher> logger)
        {
            _configuration = configuration;
            _logger = logger;
            _exchangeName = _configuration["RabbitMQ:Exchange"] ?? "EmailExchange";
            _queueName = _configuration["RabbitMQ:QueueName"] ?? "EmailQueue";
            _routingKey = _configuration["RabbitMQ:RoutingKey"] ?? "email_queue";
            _deadLetterExchange = _configuration["RabbitMQ:DeadLetterExchange"] ?? "EmailDeadLetterExchange";
            _deadLetterQueueName = _configuration["RabbitMQ:DeadLetterQueueName"] ?? "EmailDeadLetterQueue";
            _deadLetterRoutingKey = _configuration["RabbitMQ:DeadLetterRoutingKey"] ?? "email_dead_letter";
        }

        public void Publish(string sender, string recipient, string subject, string content)
        {
            if (string.IsNullOrWhiteSpace(recipient))
                throw new ValidationException("Primatelj je obavezan.");
            if (string.IsNullOrWhiteSpace(subject))
                throw new ValidationException("Naslov emaila je obavezan.");

            lock (_sync)
            {
                EnsureChannel();

                var payload = new MailQueueMessage
                {
                    Sender = sender ?? string.Empty,
                    Recipient = recipient.Trim(),
                    Subject = subject,
                    Content = content ?? string.Empty
                };

                var body = Encoding.UTF8.GetBytes(JsonSerializer.Serialize(payload));
                var props = _channel!.CreateBasicProperties();
                props.ContentType = "application/json";
                props.DeliveryMode = 2;
                props.Persistent = true;

                _channel.BasicPublish(
                    exchange: _exchangeName,
                    routingKey: _routingKey,
                    mandatory: false,
                    basicProperties: props,
                    body: body);

                _logger.LogInformation(
                    "Email message published to RabbitMQ exchange {Exchange}, routing key {RoutingKey}, recipient {Recipient}.",
                    _exchangeName,
                    _routingKey,
                    recipient);
            }
        }

        private void EnsureChannel()
        {
            if (_connection != null && _connection.IsOpen && _channel != null && _channel.IsOpen)
                return;

            DisposeConnection();

            var factory = CreateConnectionFactory();
            _connection = factory.CreateConnection();
            _connection.ConnectionShutdown += (_, args) =>
            {
                _logger.LogWarning(
                    "RabbitMQ producer connection shutdown: {Reason}. Will reconnect on next publish.",
                    args.ReplyText);
            };

            _channel = _connection.CreateModel();
            DeclareTopology(_channel);
            _logger.LogInformation("RabbitMQ producer connected to {Host}:{Port}.", factory.HostName, factory.Port);
        }

        private ConnectionFactory CreateConnectionFactory()
        {
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
                NetworkRecoveryInterval = TimeSpan.FromSeconds(10),
                RequestedConnectionTimeout = TimeSpan.FromSeconds(30),
                RequestedHeartbeat = TimeSpan.FromSeconds(60)
            };
            factory.ClientProvidedName = "CSB Mail Producer";
            return factory;
        }

        private void DeclareTopology(IModel channel)
        {
            channel.ExchangeDeclare(_deadLetterExchange, ExchangeType.Direct, durable: true, autoDelete: false);
            channel.QueueDeclare(_deadLetterQueueName, durable: true, exclusive: false, autoDelete: false, arguments: null);
            channel.QueueBind(_deadLetterQueueName, _deadLetterExchange, _deadLetterRoutingKey, arguments: null);

            var queueArgs = new Dictionary<string, object>
            {
                { "x-dead-letter-exchange", _deadLetterExchange },
                { "x-dead-letter-routing-key", _deadLetterRoutingKey }
            };

            channel.ExchangeDeclare(_exchangeName, ExchangeType.Direct, durable: true, autoDelete: false);
            channel.QueueDeclare(_queueName, durable: true, exclusive: false, autoDelete: false, arguments: queueArgs);
            channel.QueueBind(_queueName, _exchangeName, _routingKey, arguments: null);
        }

        private void DisposeConnection()
        {
            try
            {
                _channel?.Close();
                _channel?.Dispose();
            }
            catch (Exception ex)
            {
                _logger.LogDebug(ex, "Error closing RabbitMQ producer channel.");
            }
            finally
            {
                _channel = null;
            }

            try
            {
                _connection?.Close();
                _connection?.Dispose();
            }
            catch (Exception ex)
            {
                _logger.LogDebug(ex, "Error closing RabbitMQ producer connection.");
            }
            finally
            {
                _connection = null;
            }
        }

        public void Dispose()
        {
            if (_disposed)
                return;

            _disposed = true;
            lock (_sync)
            {
                DisposeConnection();
            }
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
