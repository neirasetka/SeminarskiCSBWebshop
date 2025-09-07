using CBSWebshopSeminarski.Model.Events;
using RabbitMQ.Client;
using RabbitMQ.Client.Events;
using System.Text;
using System.Text.Json;

namespace CSBWebshopSeminarski.Notifications
{
    public class RabbitMqOrderCreatedConsumer : BackgroundService
    {
        private readonly ILogger<RabbitMqOrderCreatedConsumer> _logger;
        private readonly IConfiguration _configuration;
        private readonly CBSWebshopSeminarski.Services.Services.EmailService _emailService;
        private IConnection? _connection;
        private IModel? _channel;
        private string _queueName = string.Empty;

        public RabbitMqOrderCreatedConsumer(
            ILogger<RabbitMqOrderCreatedConsumer> logger,
            IConfiguration configuration,
            CBSWebshopSeminarski.Services.Services.EmailService emailService)
        {
            _logger = logger;
            _configuration = configuration;
            _emailService = emailService;
        }

        public override Task StartAsync(CancellationToken cancellationToken)
        {
            var host = _configuration["RabbitMQ:HostName"] ?? "localhost";
            var exchange = _configuration["RabbitMQ:Exchange"] ?? "webshop.events";
            var routingKey = _configuration["RabbitMQ:OrderCreatedRoutingKey"] ?? "orders.created";

            var factory = new ConnectionFactory
            {
                HostName = host,
                DispatchConsumersAsync = true
            };
            _connection = factory.CreateConnection();
            _channel = _connection.CreateModel();
            _channel.ExchangeDeclare(exchange: exchange, type: ExchangeType.Topic, durable: true);
            _queueName = _channel.QueueDeclare(durable: true, exclusive: false, autoDelete: false).QueueName;
            _channel.QueueBind(queue: _queueName, exchange: exchange, routingKey: routingKey);

            return base.StartAsync(cancellationToken);
        }

        protected override async Task ExecuteAsync(CancellationToken stoppingToken)
        {
            if (_channel == null)
            {
                return;
            }

            var consumer = new AsyncEventingBasicConsumer(_channel);
            consumer.Received += async (model, ea) =>
            {
                try
                {
                    var body = ea.Body.ToArray();
                    var json = Encoding.UTF8.GetString(body);
                    var evt = JsonSerializer.Deserialize<OrderCreatedEvent>(json);
                    if (evt != null)
                    {
                        _logger.LogInformation("Received OrderCreatedEvent: {OrderNumber}", evt.OrderNumber);
                        if (!string.IsNullOrWhiteSpace(evt.UserEmail))
                        {
                            var subject = $"Order Confirmation #{evt.OrderNumber}";
                            var message = $"Thank you for your order #{evt.OrderNumber}. Total: {evt.Amount}.";
                            await _emailService.SendEmailAsync(evt.UserEmail, subject, message);
                        }
                    }
                    _channel!.BasicAck(ea.DeliveryTag, multiple: false);
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex, "Error processing OrderCreatedEvent");
                    _channel!.BasicNack(ea.DeliveryTag, multiple: false, requeue: true);
                }
            };

            _channel.BasicQos(0, 1, false);
            _channel.BasicConsume(queue: _queueName, autoAck: false, consumer: consumer);

            while (!stoppingToken.IsCancellationRequested)
            {
                await Task.Delay(1000, stoppingToken);
            }
        }

        public override Task StopAsync(CancellationToken cancellationToken)
        {
            try
            {
                _channel?.Close();
                _connection?.Close();
            }
            catch { }
            return base.StopAsync(cancellationToken);
        }
    }
}
