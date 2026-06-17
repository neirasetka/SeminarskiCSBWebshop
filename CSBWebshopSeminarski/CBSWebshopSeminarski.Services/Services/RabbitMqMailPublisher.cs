using CBSWebshopSeminarski.Services.Exceptions;
using CBSWebshopSeminarski.Services.RabbitMq;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using RabbitMQ.Client;
using System.Text;
using System.Text.Json;

namespace CBSWebshopSeminarski.Services.Services
{
    public class RabbitMqMailPublisher
    {
        private readonly IRabbitMqChannelPool _channelPool;
        private readonly IConfiguration _configuration;
        private readonly ILogger<RabbitMqMailPublisher> _logger;
        private readonly RabbitMqTopologyNames _topology;

        public RabbitMqMailPublisher(
            IRabbitMqChannelPool channelPool,
            IConfiguration configuration,
            ILogger<RabbitMqMailPublisher> logger)
        {
            _channelPool = channelPool;
            _configuration = configuration;
            _logger = logger;
            _topology = RabbitMqConnectionSettings.ReadTopology(configuration);
        }

        public void Publish(string sender, string recipient, string subject, string content)
        {
            if (string.IsNullOrWhiteSpace(recipient))
                throw new ValidationException("Primatelj je obavezan.");
            if (string.IsNullOrWhiteSpace(subject))
                throw new ValidationException("Naslov emaila je obavezan.");

            var payload = new MailQueueMessage
            {
                Sender = sender ?? string.Empty,
                Recipient = recipient.Trim(),
                Subject = subject,
                Content = content ?? string.Empty
            };

            var body = Encoding.UTF8.GetBytes(JsonSerializer.Serialize(payload));
            IModel? channel = null;
            try
            {
                channel = _channelPool.RentChannel();
                var props = channel.CreateBasicProperties();
                props.ContentType = "application/json";
                props.DeliveryMode = 2;
                props.Persistent = true;

                channel.BasicPublish(
                    exchange: _topology.Exchange,
                    routingKey: _topology.RoutingKey,
                    mandatory: false,
                    basicProperties: props,
                    body: body);

                _logger.LogInformation(
                    "Email message published to RabbitMQ exchange {Exchange}, routing key {RoutingKey}, recipient {Recipient}.",
                    _topology.Exchange,
                    _topology.RoutingKey,
                    recipient);
            }
            finally
            {
                if (channel != null)
                    _channelPool.ReturnChannel(channel);
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
