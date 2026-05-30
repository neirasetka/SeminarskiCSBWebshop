using MailKit.Net.Smtp;
using MailKit.Security;
using MimeKit;
using MimeKit.Text;
using Newtonsoft.Json;
using RabbitMQ.Client;
using RabbitMQ.Client.Events;
using System.Collections.Generic;
using System.Text;

namespace CSBWebshopSeminarski.Notifications
{
    public class RabbitMqEmailConsumer : BackgroundService
    {
        private readonly ILogger<RabbitMqEmailConsumer> _logger;
        private readonly IConfiguration _configuration;
        private IConnection? _connection;
        private IModel? _channel;
        private string _queueName = "EmailQueue";
        private string _exchangeName = "EmailExchange";
        private string _routingKey = "email_queue";
        private string _deadLetterExchange = "EmailDeadLetterExchange";
        private string _deadLetterQueueName = "EmailDeadLetterQueue";
        private string _deadLetterRoutingKey = "email_dead_letter";
        private bool _consumerStarted;
        private CancellationToken _stoppingToken;

        public RabbitMqEmailConsumer(
            ILogger<RabbitMqEmailConsumer> logger,
            IConfiguration configuration)
        {
            _logger = logger;
            _configuration = configuration;
        }

        public override Task StartAsync(CancellationToken cancellationToken)
        {
            _exchangeName = _configuration["RabbitMQ:Exchange"] ?? "EmailExchange";
            _queueName = _configuration["RabbitMQ:QueueName"] ?? "EmailQueue";
            _routingKey = _configuration["RabbitMQ:RoutingKey"] ?? "email_queue";
            _deadLetterExchange = _configuration["RabbitMQ:DeadLetterExchange"] ?? "EmailDeadLetterExchange";
            _deadLetterQueueName = _configuration["RabbitMQ:DeadLetterQueueName"] ?? "EmailDeadLetterQueue";
            _deadLetterRoutingKey = _configuration["RabbitMQ:DeadLetterRoutingKey"] ?? "email_dead_letter";
            return base.StartAsync(cancellationToken);
        }

        protected override async Task ExecuteAsync(CancellationToken stoppingToken)
        {
            _stoppingToken = stoppingToken;

            while (!stoppingToken.IsCancellationRequested)
            {
                if (_channel == null || !_channel.IsOpen || _connection == null || !_connection.IsOpen)
                {
                    TryConnect();
                }

                if ((_channel == null || !_channel.IsOpen) && !stoppingToken.IsCancellationRequested)
                {
                    await Task.Delay(5000, stoppingToken);
                    continue;
                }

                if (!_consumerStarted)
                {
                    StartConsumer();
                }

                await Task.Delay(1000, stoppingToken);
            }
        }

        public override Task StopAsync(CancellationToken cancellationToken)
        {
            try
            {
                _channel?.Close();
                _connection?.Close();
                _channel?.Dispose();
                _connection?.Dispose();
            }
            catch (Exception ex)
            {
                _logger.LogDebug(ex, "Error while closing RabbitMQ connection during shutdown.");
            }

            return base.StopAsync(cancellationToken);
        }

        private void TryConnect()
        {
            try
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
                    RequestedConnectionTimeout = TimeSpan.FromSeconds(30),
                    RequestedHeartbeat = TimeSpan.FromSeconds(60),
                    AutomaticRecoveryEnabled = true,
                    NetworkRecoveryInterval = TimeSpan.FromSeconds(10)
                };

                _connection = factory.CreateConnection();
                _channel = _connection.CreateModel();
                DeclareEmailTopology(_channel);
                _consumerStarted = false;
                _logger.LogInformation(
                    "RabbitMQ connected at {Host}:{Port}. Dead-letter queue: {DeadLetterQueue}.",
                    host,
                    port,
                    _deadLetterQueueName);
            }
            catch (Exception ex)
            {
                _logger.LogWarning(ex, "RabbitMQ unavailable. Notifications consumer will retry.");
            }
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

        private void StartConsumer()
        {
            if (_channel == null)
            {
                return;
            }

            var consumer = new AsyncEventingBasicConsumer(_channel);
            consumer.Received += OnMessageReceivedAsync;

            _channel.BasicQos(0, 1, false);
            _channel.BasicConsume(queue: _queueName, autoAck: false, consumer: consumer);
            _consumerStarted = true;
            _logger.LogInformation("RabbitMQ email consumer started on queue {QueueName}.", _queueName);
        }

        private async Task OnMessageReceivedAsync(object sender, BasicDeliverEventArgs ea)
        {
            var deliveryTag = ea.DeliveryTag;

            try
            {
                var body = ea.Body.ToArray();
                var message = Encoding.UTF8.GetString(body);
                await SendEmailAsync(message, _stoppingToken);
                _channel!.BasicAck(deliveryTag, multiple: false);
            }
            catch (InvalidEmailMessageException ex)
            {
                _logger.LogError(ex, "Invalid email queue payload; sending to dead-letter queue.");
                RejectMessage(deliveryTag, requeue: false);
            }
            catch (AuthenticationException ex)
            {
                _logger.LogError(ex, "SMTP authentication failed; sending message to dead-letter queue.");
                RejectMessage(deliveryTag, requeue: false);
            }
            catch (SmtpProtocolException ex) when (ex.Message.Contains("Too many login attempts", StringComparison.OrdinalIgnoreCase))
            {
                _logger.LogError(ex, "SMTP rate limit reached; sending message to dead-letter queue.");
                RejectMessage(deliveryTag, requeue: false);
            }
            catch (OperationCanceledException) when (_stoppingToken.IsCancellationRequested)
            {
                _logger.LogInformation("Email processing cancelled during shutdown; requeueing message.");
                RejectMessage(deliveryTag, requeue: true);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Transient error processing email queue message; requeueing for retry.");
                RejectMessage(deliveryTag, requeue: true);
            }
        }

        private void RejectMessage(ulong deliveryTag, bool requeue)
        {
            try
            {
                _channel!.BasicNack(deliveryTag, multiple: false, requeue: requeue);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to nack RabbitMQ message with delivery tag {DeliveryTag}.", deliveryTag);
            }
        }

        private async Task SendEmailAsync(string message, CancellationToken cancellationToken)
        {
            var smtpServer = _configuration["Smtp:Host"] ?? Environment.GetEnvironmentVariable("SMTP_SERVER") ?? "smtp.gmail.com";
            var smtpPort = int.TryParse(_configuration["Smtp:Port"], out var port)
                ? port
                : int.TryParse(Environment.GetEnvironmentVariable("SMTP_PORT"), out var envPort) ? envPort : 587;
            var smtpUser = _configuration["Smtp:User"] ?? Environment.GetEnvironmentVariable("SMTP_USERNAME") ?? string.Empty;
            // Gmail app passwords are often shown with spaces; auth requires contiguous string.
            var smtpPass = (_configuration["Smtp:Pass"] ?? Environment.GetEnvironmentVariable("SMTP_PASSWORD") ?? string.Empty)
                .Replace(" ", string.Empty)
                .Trim();

            MailDto? emailData;
            try
            {
                emailData = JsonConvert.DeserializeObject<MailDto>(message);
            }
            catch (JsonException ex)
            {
                throw new InvalidEmailMessageException("Email queue payload is not valid JSON.", ex);
            }

            if (emailData == null
                || string.IsNullOrWhiteSpace(emailData.Recipient)
                || string.IsNullOrWhiteSpace(emailData.Subject))
            {
                throw new InvalidEmailMessageException("Email queue payload is missing required fields.");
            }

            var mailObj = new MimeMessage();
            mailObj.From.Add(MailboxAddress.Parse(!string.IsNullOrWhiteSpace(emailData.Sender) ? emailData.Sender : smtpUser));
            mailObj.To.Add(MailboxAddress.Parse(emailData.Recipient));
            mailObj.Subject = emailData.Subject;
            mailObj.Body = new TextPart(TextFormat.Plain) { Text = emailData.Content ?? string.Empty };

            using var smtpClient = new SmtpClient();
            var secureOption = smtpPort == 465 ? SecureSocketOptions.SslOnConnect : SecureSocketOptions.StartTls;
            await smtpClient.ConnectAsync(smtpServer, smtpPort, secureOption, cancellationToken);
            smtpClient.AuthenticationMechanisms.Remove("XOAUTH2");
            await smtpClient.AuthenticateAsync(smtpUser, smtpPass, cancellationToken);
            await smtpClient.SendAsync(mailObj, cancellationToken);
            await smtpClient.DisconnectAsync(true, cancellationToken);
        }

        private sealed class InvalidEmailMessageException : Exception
        {
            public InvalidEmailMessageException(string message) : base(message)
            {
            }

            public InvalidEmailMessageException(string message, Exception innerException)
                : base(message, innerException)
            {
            }
        }

        private class MailDto
        {
            public string Sender { get; set; } = string.Empty;
            public string Recipient { get; set; } = string.Empty;
            public string Subject { get; set; } = string.Empty;
            public string Content { get; set; } = string.Empty;
        }
    }
}
