using CBSWebshopSeminarski.Services.RabbitMq;
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
        private readonly IRabbitMqConnectionProvider _connectionProvider;
        private readonly SemaphoreSlim _processingLock = new(1, 1);
        private IModel? _consumerChannel;
        private RabbitMqTopologyNames _topology = new(
            "EmailExchange", "EmailQueue", "email_queue",
            "EmailDeadLetterExchange", "EmailDeadLetterQueue", "email_dead_letter");
        private string? _consumerTag;
        private bool _consumerRegistered;

        public RabbitMqEmailConsumer(
            ILogger<RabbitMqEmailConsumer> logger,
            IConfiguration configuration,
            IRabbitMqConnectionProvider connectionProvider)
        {
            _logger = logger;
            _configuration = configuration;
            _connectionProvider = connectionProvider;
        }

        public override Task StartAsync(CancellationToken cancellationToken)
        {
            _topology = RabbitMqConnectionSettings.ReadTopology(_configuration);
            return base.StartAsync(cancellationToken);
        }

        protected override async Task ExecuteAsync(CancellationToken stoppingToken)
        {
            while (!stoppingToken.IsCancellationRequested)
            {
                try
                {
                    if (!IsConsumerReady())
                    {
                        await ConnectConsumerAsync(stoppingToken);
                    }

                    if (!IsConsumerReady())
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
                    TeardownConsumerChannel();
                    await Task.Delay(TimeSpan.FromSeconds(5), stoppingToken);
                }
            }
        }

        public override Task StopAsync(CancellationToken cancellationToken)
        {
            TeardownConsumerChannel();
            return base.StopAsync(cancellationToken);
        }

        private bool IsConsumerReady() =>
            _consumerChannel != null && _consumerChannel.IsOpen;

        private async Task ConnectConsumerAsync(CancellationToken cancellationToken)
        {
            TeardownConsumerChannel();

            try
            {
                var connection = _connectionProvider.GetConnection();
                _consumerChannel = connection.CreateModel();
                RabbitMqEmailTopology.Declare(_consumerChannel, _configuration);
                _consumerRegistered = false;
                _logger.LogInformation("RabbitMQ email consumer channel ready on queue {QueueName}.", _topology.QueueName);
            }
            catch (BrokerUnreachableException ex)
            {
                _logger.LogWarning(ex, "RabbitMQ broker unreachable. Retrying...");
                TeardownConsumerChannel();
            }
            catch (OperationInterruptedException ex)
            {
                _logger.LogError(
                    ex,
                    "RabbitMQ topology declaration failed. Ensure queue {QueueName} was not created with different arguments.",
                    _topology.QueueName);
                TeardownConsumerChannel();
            }

            await Task.CompletedTask;
        }

        private void RegisterConsumer()
        {
            if (_consumerChannel == null)
                return;

            var consumer = new AsyncEventingBasicConsumer(_consumerChannel);
            consumer.Received += OnMessageReceivedAsync;

            _consumerChannel.BasicQos(prefetchSize: 0, prefetchCount: 1, global: false);
            _consumerTag = _consumerChannel.BasicConsume(
                queue: _topology.QueueName,
                autoAck: false,
                consumer: consumer);
            _consumerRegistered = true;
            _logger.LogInformation("RabbitMQ email consumer listening on queue {QueueName}.", _topology.QueueName);
        }

        private async Task OnMessageReceivedAsync(object sender, BasicDeliverEventArgs ea)
        {
            await _processingLock.WaitAsync();
            try
            {
                var body = ea.Body.ToArray();
                var message = Encoding.UTF8.GetString(body);
                await SendEmailAsync(message, CancellationToken.None);
                _consumerChannel!.BasicAck(ea.DeliveryTag, multiple: false);
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
                _consumerChannel?.BasicNack(deliveryTag, multiple: false, requeue: requeue);
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

        private void TeardownConsumerChannel()
        {
            _consumerRegistered = false;
            _consumerTag = null;

            try
            {
                _consumerChannel?.Close();
                _consumerChannel?.Dispose();
            }
            catch (Exception ex)
            {
                _logger.LogDebug(ex, "Error closing RabbitMQ consumer channel.");
            }
            finally
            {
                _consumerChannel = null;
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
