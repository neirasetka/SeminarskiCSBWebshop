using MailKit.Net.Smtp;
using MailKit.Security;
using MimeKit;
using MimeKit.Text;
using Newtonsoft.Json;
using RabbitMQ.Client;
using RabbitMQ.Client.Events;
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
        private bool _consumerStarted;

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
            return base.StartAsync(cancellationToken);
        }

        protected override async Task ExecuteAsync(CancellationToken stoppingToken)
        {
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
            catch { }
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
                _channel.ExchangeDeclare(exchange: _exchangeName, type: ExchangeType.Direct, durable: true);
                _channel.QueueDeclare(queue: _queueName, durable: true, exclusive: false, autoDelete: false, arguments: null);
                _channel.QueueBind(queue: _queueName, exchange: _exchangeName, routingKey: _routingKey, arguments: null);
                _consumerStarted = false;
                _logger.LogInformation("RabbitMQ connected at {Host}:{Port}.", host, port);
            }
            catch (Exception ex)
            {
                _logger.LogWarning(ex, "RabbitMQ unavailable. Notifications consumer will retry.");
            }
        }

        private void StartConsumer()
        {
            if (_channel == null)
            {
                return;
            }

            var consumer = new EventingBasicConsumer(_channel);
            consumer.Received += (model, ea) =>
            {
                try
                {
                    var body = ea.Body.ToArray();
                    var message = Encoding.UTF8.GetString(body);
                    SendEmail(message);
                    _channel!.BasicAck(ea.DeliveryTag, multiple: false);
                }
                catch (AuthenticationException ex)
                {
                    _logger.LogError(ex, "SMTP authentication failed; dropping message to avoid infinite retry loop.");
                    _channel!.BasicNack(ea.DeliveryTag, multiple: false, requeue: false);
                }
                catch (SmtpProtocolException ex) when (ex.Message.Contains("Too many login attempts", StringComparison.OrdinalIgnoreCase))
                {
                    _logger.LogError(ex, "SMTP rate limit reached; dropping message to avoid immediate retry storm.");
                    _channel!.BasicNack(ea.DeliveryTag, multiple: false, requeue: false);
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex, "Error processing email queue message");
                    _channel!.BasicNack(ea.DeliveryTag, multiple: false, requeue: true);
                }
            };

            _channel.BasicQos(0, 1, false);
            _channel.BasicConsume(queue: _queueName, autoAck: false, consumer: consumer);
            _consumerStarted = true;
            _logger.LogInformation("RabbitMQ email consumer started on queue {QueueName}.", _queueName);
        }

        private void SendEmail(string message)
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

            var emailData = JsonConvert.DeserializeObject<MailDto>(message);
            if (emailData == null)
            {
                _logger.LogWarning("Skipping email send because payload could not be parsed.");
                return;
            }

            var mailObj = new MimeMessage();
            mailObj.From.Add(MailboxAddress.Parse(!string.IsNullOrWhiteSpace(emailData.Sender) ? emailData.Sender : smtpUser));
            mailObj.To.Add(MailboxAddress.Parse(emailData.Recipient));
            mailObj.Subject = emailData.Subject;
            mailObj.Body = new TextPart(TextFormat.Plain) { Text = emailData.Content };

            using var smtpClient = new SmtpClient();
            var secureOption = smtpPort == 465 ? SecureSocketOptions.SslOnConnect : SecureSocketOptions.StartTls;
            smtpClient.Connect(smtpServer, smtpPort, secureOption);
            smtpClient.AuthenticationMechanisms.Remove("XOAUTH2");
            smtpClient.Authenticate(smtpUser, smtpPass);
            smtpClient.Send(mailObj);
            smtpClient.Disconnect(true);
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
