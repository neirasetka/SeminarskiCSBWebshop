using CBSWebshopSeminarski.Services.Interfaces;
using RabbitMQ.Client;
using System.Text;
using System.Text.Json;

namespace CBSWebshopSeminarski.Services.Services
{
    public class RabbitMqEventPublisher : IEventPublisher, IDisposable
    {
        private readonly IConnection _connection;
        private readonly IModel _channel;
        private readonly string _exchangeName;

        public RabbitMqEventPublisher(string hostName, string exchangeName)
        {
            _exchangeName = exchangeName;
            var factory = new ConnectionFactory
            {
                HostName = hostName,
                DispatchConsumersAsync = true
            };
            _connection = factory.CreateConnection();
            _channel = _connection.CreateModel();
            _channel.ExchangeDeclare(exchange: _exchangeName, type: ExchangeType.Topic, durable: true);
        }

        public Task PublishAsync<T>(string routingKey, T message, CancellationToken cancellationToken = default)
        {
            var bodyString = JsonSerializer.Serialize(message);
            var body = Encoding.UTF8.GetBytes(bodyString);

            var props = _channel.CreateBasicProperties();
            props.ContentType = "application/json";
            props.DeliveryMode = 2;

            _channel.BasicPublish(exchange: _exchangeName, routingKey: routingKey, basicProperties: props, body: body);
            return Task.CompletedTask;
        }

        public void Dispose()
        {
            try
            {
                _channel?.Close();
                _channel?.Dispose();
                _connection?.Close();
                _connection?.Dispose();
            }
            catch
            {
            }
        }
    }
}
