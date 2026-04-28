using Microsoft.Extensions.Configuration;
using RabbitMQ.Client;
using System.Text;
using System.Text.Json;

namespace CBSWebshopSeminarski.Services.Services
{
    public class RabbitMqMailPublisher
    {
        private readonly IConfiguration _configuration;
        private readonly string _exchangeName;
        private readonly string _queueName;
        private readonly string _routingKey;

        public RabbitMqMailPublisher(IConfiguration configuration)
        {
            _configuration = configuration;
            _exchangeName = _configuration["RabbitMQ:Exchange"] ?? "EmailExchange";
            _queueName = _configuration["RabbitMQ:QueueName"] ?? "EmailQueue";
            _routingKey = _configuration["RabbitMQ:RoutingKey"] ?? "email_queue";
        }

        public void Publish(string sender, string recipient, string subject, string content)
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
                Password = password
            };
            factory.ClientProvidedName = "CSB Mail Producer";

            using var connection = factory.CreateConnection();
            using var channel = connection.CreateModel();
            channel.ExchangeDeclare(_exchangeName, ExchangeType.Direct, durable: true);
            channel.QueueDeclare(_queueName, durable: true, exclusive: false, autoDelete: false, arguments: null);
            channel.QueueBind(_queueName, _exchangeName, _routingKey, null);

            var payload = new MailQueueMessage
            {
                Sender = sender,
                Recipient = recipient,
                Subject = subject,
                Content = content
            };

            var message = JsonSerializer.Serialize(payload);
            var body = Encoding.UTF8.GetBytes(message);
            var props = channel.CreateBasicProperties();
            props.ContentType = "application/json";
            props.DeliveryMode = 2;

            channel.BasicPublish(
                exchange: _exchangeName,
                routingKey: _routingKey,
                basicProperties: props,
                body: body);
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
