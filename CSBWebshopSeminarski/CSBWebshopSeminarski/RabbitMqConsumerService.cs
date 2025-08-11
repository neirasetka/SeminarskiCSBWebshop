using System.Text;
using CBSWebshopSeminarski.Services.Interfaces;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Configuration;
using RabbitMQ.Client;
using RabbitMQ.Client.Events;

namespace CSBWebshopSeminarski
{
    public class RabbitMqConsumerService : BackgroundService
    {
        private readonly IRabbitMqConnection _connectionProvider;
        private readonly ILogger<RabbitMqConsumerService> _logger;
        private readonly IConfiguration _configuration;

        public RabbitMqConsumerService(IRabbitMqConnection connectionProvider, ILogger<RabbitMqConsumerService> logger, IConfiguration configuration)
        {
            _connectionProvider = connectionProvider;
            _logger = logger;
            _configuration = configuration;
        }

        protected override Task ExecuteAsync(CancellationToken stoppingToken)
        {
            return Task.Run(async () =>
            {
                var section = _configuration.GetSection("RabbitMQ");
                var queue = section["Queue"] ?? string.Empty;
                var exchange = section["Exchange"] ?? string.Empty;
                var route = section["RoutingKey"] ?? "#";

                if (string.IsNullOrWhiteSpace(queue))
                {
                    _logger.LogInformation("RabbitMQ consumer disabled: no queue configured.");
                    return;
                }

                var connection = _connectionProvider.GetConnection();
                using var channel = connection.CreateModel();

                if (!string.IsNullOrWhiteSpace(exchange))
                {
                    channel.ExchangeDeclare(exchange: exchange, type: ExchangeType.Topic, durable: true, autoDelete: false);
                    channel.QueueDeclare(queue: queue, durable: true, exclusive: false, autoDelete: false, arguments: null);
                    channel.QueueBind(queue, exchange, route);
                }
                else
                {
                    channel.QueueDeclare(queue: queue, durable: true, exclusive: false, autoDelete: false, arguments: null);
                }

                var consumer = new AsyncEventingBasicConsumer(channel);
                consumer.Received += async (sender, ea) =>
                {
                    try
                    {
                        var body = ea.Body.ToArray();
                        var text = Encoding.UTF8.GetString(body);
                        _logger.LogInformation("[RabbitMQ] Received: {Text}", text);
                        // TODO: add domain-specific processing here
                        channel.BasicAck(deliveryTag: ea.DeliveryTag, multiple: false);
                    }
                    catch (Exception ex)
                    {
                        _logger.LogError(ex, "RabbitMQ consumer error");
                        channel.BasicNack(ea.DeliveryTag, multiple: false, requeue: true);
                    }

                    await Task.CompletedTask;
                };

                channel.BasicQos(0, 10, false);
                channel.BasicConsume(queue: queue, autoAck: false, consumer: consumer);

                while (!stoppingToken.IsCancellationRequested)
                {
                    await Task.Delay(TimeSpan.FromSeconds(5), stoppingToken);
                }
            }, stoppingToken);
        }
    }
}