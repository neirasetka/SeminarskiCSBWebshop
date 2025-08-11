using System.Text;
using CBSWebshopSeminarski.Services.Interfaces;
using Microsoft.Extensions.Configuration;
using RabbitMQ.Client;

namespace CBSWebshopSeminarski.Services.Services
{
    public class RabbitMqPublisher : IRabbitMqPublisher
    {
        private readonly IRabbitMqConnection _connectionProvider;
        private readonly IConfiguration _configuration;

        public RabbitMqPublisher(IRabbitMqConnection connectionProvider, IConfiguration configuration)
        {
            _connectionProvider = connectionProvider;
            _configuration = configuration;
        }

        public Task PublishAsync(string message, string? routingKey = null, CancellationToken cancellationToken = default)
        {
            var connection = _connectionProvider.GetConnection();
            using var channel = connection.CreateModel();

            var section = _configuration.GetSection("RabbitMQ");
            var exchange = section["Exchange"] ?? string.Empty;
            var route = routingKey ?? section["RoutingKey"] ?? string.Empty;
            var queue = section["Queue"] ?? string.Empty;

            // Declare topology if configured
            if (!string.IsNullOrWhiteSpace(exchange))
            {
                channel.ExchangeDeclare(exchange: exchange, type: ExchangeType.Topic, durable: true, autoDelete: false);
            }
            if (!string.IsNullOrWhiteSpace(queue))
            {
                channel.QueueDeclare(queue: queue, durable: true, exclusive: false, autoDelete: false, arguments: null);
                if (!string.IsNullOrWhiteSpace(exchange))
                {
                    var bindKey = string.IsNullOrWhiteSpace(route) ? "#" : route;
                    channel.QueueBind(queue: queue, exchange: exchange, routingKey: bindKey);
                }
            }

            var body = Encoding.UTF8.GetBytes(message);
            var props = channel.CreateBasicProperties();
            props.Persistent = true;

            if (!string.IsNullOrWhiteSpace(exchange))
            {
                channel.BasicPublish(exchange: exchange, routingKey: route, basicProperties: props, body: body);
            }
            else if (!string.IsNullOrWhiteSpace(queue))
            {
                channel.BasicPublish(exchange: string.Empty, routingKey: queue, basicProperties: props, body: body);
            }
            else
            {
                throw new InvalidOperationException("RabbitMQ configuration must specify either Exchange or Queue.");
            }

            return Task.CompletedTask;
        }
    }
}