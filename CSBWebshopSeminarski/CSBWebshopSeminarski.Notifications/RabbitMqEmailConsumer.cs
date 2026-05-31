using MailKit.Net.Smtp;
using MailKit.Security;
using MimeKit;
using MimeKit.Text;
using Newtonsoft.Json;
using RabbitMQ.Client;
using RabbitMQ.Client.Events;
using RabbitMQ.Client.Exceptions;
using System.Text;

namespace CSBWebshopSeminarski.Notifications
{
    public class RabbitMqEmailConsumer : BackgroundService
    {
        private readonly ILogger<RabbitMqEmailConsumer> _logger;
        private readonly IConfiguration _configuration;
        private readonly SemaphoreSlim _processingLock = new(1, 1);
        private IConnection? _connection;
        private IModel? _channel;
        private string _queueName = "EmailQueue";
        private string _exchangeName = "EmailExchange";
        private string _routingKey = "email_queue";
        private string _deadLetterExchange = "EmailDeadLetterExchange";
        private string _deadLetterQueueName = "EmailDeadLetterQueue";
        private string _deadLetterRoutingKey = "email_dead_letter";
        private string? _consumerTag;
        private bool _consumerRegistered;

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
            while (!stoppingToken.IsCancellationRequested)
            {
                try
                {
                    if (!IsConnected())
                    {
                        await ConnectAsync(stoppingToken);
                    }

                    if (!IsConnected())
                    {
                        await Task.Delay(TimeSpan.FromSeconds(5), stoppingToken);
                        continue;
                    }

                    if (!_consumerRegistered)
                    {
                        RegisterConsumer();
                    }

                    await Task.Delay(TimeSpan.FromSeconds(1), stoppingToken);
                }
                catch (OperationCanceledException) when (stoppingToken.IsCancellationRequested)
                {
                    break;
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex, "Unexpected error in RabbitMQ email consumer loop.");
                    TeardownConnection();
                    await Task.Delay(TimeSpan.FromSeconds(5), stoppingToken);
                }
            }
        }

        public override Task StopAsync(CancellationToken cancellationToken)
        {
            TeardownConnection();
            return base.StopAsync(cancellationToken);
        }

        private bool IsConnected() =>
            _connection != null && _connection.IsOpen && _channel != null && _channel.IsOpen;

        private async Task ConnectAsync(CancellationToken cancellationToken)
        {
            TeardownConnection();

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
                NetworkRecoveryInterval = TimeSpan.FromSeconds(10),
                DispatchConsumersAsync = true
            };

            try
            {
                _connection = factory.CreateConnection();
                _connection.ConnectionShutdown += (_, args) =>
                {
                    _logger.LogWarning(
                        "RabbitMQ consumer connection shutdown: {Reason}. Will reconnect.",
                        args.ReplyText);
                    _consumerRegistered = false;
                };

                _channel = _connection.CreateModel();
                DeclareTopology(_channel);
                _consumerRegistered = false;
                _logger.LogInformation("RabbitMQ email consumer connected at {Host}:{Port}.", host, port);
            }
            catch (BrokerUnreachableException ex)
            {
                _logger.LogWarning(ex, "RabbitMQ broker unreachable at {Host}:{Port}. Retrying...", host, port);
                TeardownConnection();
            }
            catch (OperationInterruptedException ex)
            {
                _logger.LogError(
                    ex,
                    "RabbitMQ topology declaration failed. Ensure queue {QueueName} was not created with different arguments.",
                    _queueName);
                TeardownConnection();
            }

            await Task.CompletedTask;
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

        private void RegisterConsumer()
        {
            if (_channel == null)
                return;

            var consumer = new AsyncEventingBasicConsumer(_channel);
            consumer.Received += OnMessageReceivedAsync;

            _channel.BasicQos(prefetchSize: 0, prefetchCount: 1, global: false);
            _consumerTag = _channel.BasicConsume(
                queue: _queueName,
                autoAck: false,
                consumer: consumer);
            _consumerRegistered = true;
            _logger.LogInformation("RabbitMQ email consumer listening on queue {QueueName}.", _queueName);
        }

        private async Task OnMessageReceivedAsync(object sender, BasicDeliverEventArgs ea)
        {
            await _processingLock.WaitAsync();
            try
            {
                var body = ea.Body.ToArray();
                var message = Encoding.UTF8.GetString(body);
                await SendEmailAsync(message, CancellationToken.None);
                _channel!.BasicAck(ea.DeliveryTag, multiple: false);
            }
            catch (InvalidEmailMessageException ex)
            {
                _logger.LogError(ex, "Invalid email payload; discarding message (delivery tag {DeliveryTag}).", ea.DeliveryTag);
                SafeNack(ea.DeliveryTag, requeue: false);
            }
            catch (AuthenticationException ex)
            {
                _logger.LogError(ex, "SMTP authentication failed; discarding message (delivery tag {DeliveryTag}).", ea.DeliveryTag);
                SafeNack(ea.DeliveryTag, requeue: false);
            }
            catch (SmtpProtocolException ex) when (ex.Message.Contains("Too many login attempts", StringComparison.OrdinalIgnoreCase))
            {
                _logger.LogError(ex, "SMTP rate limit reached; requeueing message (delivery tag {DeliveryTag}).", ea.DeliveryTag);
                SafeNack(ea.DeliveryTag, requeue: true);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Transient error sending email; requeueing message (delivery tag {DeliveryTag}).", ea.DeliveryTag);
                SafeNack(ea.DeliveryTag, requeue: true);
            }
            finally
            {
                _processingLock.Release();
            }
        }

        private void SafeNack(ulong deliveryTag, bool requeue)
        {
            try
            {
                _channel?.BasicNack(deliveryTag, multiple: false, requeue: requeue);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to nack RabbitMQ message with delivery tag {DeliveryTag}.", deliveryTag);
            }
        }

        private async Task SendEmailAsync(string message, CancellationToken cancellationToken)
        {
            var smtpServer = FirstNonEmpty(
                _configuration["Smtp:Host"],
                Environment.GetEnvironmentVariable("SMTP_SERVER"),
                "smtp.gmail.com");
            var smtpPort = int.TryParse(_configuration["Smtp:Port"], out var port)
                ? port
                : int.TryParse(Environment.GetEnvironmentVariable("SMTP_PORT"), out var envPort) ? envPort : 587;
            var smtpUser = FirstNonEmpty(
                _configuration["Smtp:User"],
                Environment.GetEnvironmentVariable("SMTP_USERNAME"));
            var smtpPass = FirstNonEmpty(
                    _configuration["Smtp:Pass"],
                    Environment.GetEnvironmentVariable("SMTP_PASSWORD"))
                .Replace(" ", string.Empty);

            if (string.IsNullOrWhiteSpace(smtpUser) || string.IsNullOrWhiteSpace(smtpPass))
            {
                throw new AuthenticationException(
                    "SMTP credentials are not configured. Set Smtp:User/Smtp:Pass or SMTP_USERNAME/SMTP_PASSWORD.");
            }

            MailDto? emailData;
            try
            {
                emailData = JsonConvert.DeserializeObject<MailDto>(message);
            }
            catch (JsonException ex)
            {
                throw new InvalidEmailMessageException("Email queue payload is not valid JSON.", ex);
            }

            if (emailData == null)
            {
                throw new InvalidEmailMessageException("Email queue payload deserialized to null.");
            }

            if (string.IsNullOrWhiteSpace(emailData.Recipient))
            {
                throw new InvalidEmailMessageException("Email queue payload is missing Recipient.");
            }

            if (string.IsNullOrWhiteSpace(emailData.Subject))
            {
                throw new InvalidEmailMessageException("Email queue payload is missing Subject.");
            }

            var fromAddress = !string.IsNullOrWhiteSpace(emailData.Sender) ? emailData.Sender : smtpUser;

            var mailObj = new MimeMessage();
            mailObj.From.Add(MailboxAddress.Parse(fromAddress));
            mailObj.To.Add(MailboxAddress.Parse(emailData.Recipient));
            mailObj.Subject = emailData.Subject;
            mailObj.Body = new TextPart(TextFormat.Plain) { Text = emailData.Content ?? string.Empty };

            using var smtpClient = new SmtpClient();
            smtpClient.Timeout = 30_000;
            var secureOption = smtpPort == 465 ? SecureSocketOptions.SslOnConnect : SecureSocketOptions.StartTls;
            await smtpClient.ConnectAsync(smtpServer, smtpPort, secureOption, cancellationToken);
            smtpClient.AuthenticationMechanisms.Remove("XOAUTH2");
            await smtpClient.AuthenticateAsync(smtpUser, smtpPass, cancellationToken);
            await smtpClient.SendAsync(mailObj, cancellationToken);
            await smtpClient.DisconnectAsync(true, cancellationToken);

            _logger.LogInformation("Email sent via SMTP to {Recipient}. Subject: {Subject}", emailData.Recipient, emailData.Subject);
        }

        private void TeardownConnection()
        {
            _consumerRegistered = false;
            _consumerTag = null;

            try
            {
                _channel?.Close();
                _channel?.Dispose();
            }
            catch (Exception ex)
            {
                _logger.LogDebug(ex, "Error closing RabbitMQ consumer channel.");
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
                _logger.LogDebug(ex, "Error closing RabbitMQ consumer connection.");
            }
            finally
            {
                _connection = null;
            }
        }

        private static string FirstNonEmpty(params string?[] values)
        {
            foreach (var value in values)
            {
                if (!string.IsNullOrWhiteSpace(value))
                {
                    return value.Trim();
                }
            }

            return string.Empty;
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
