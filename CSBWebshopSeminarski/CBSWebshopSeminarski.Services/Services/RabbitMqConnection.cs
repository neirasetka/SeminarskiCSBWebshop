using CBSWebshopSeminarski.Services.Interfaces;
using Microsoft.Extensions.Configuration;
using RabbitMQ.Client;

namespace CBSWebshopSeminarski.Services.Services
{
    public sealed class RabbitMqConnection : IRabbitMqConnection, IDisposable
    {
        private readonly IConfiguration _configuration;
        private IConnection? _connection;
        private readonly object _syncRoot = new object();

        public RabbitMqConnection(IConfiguration configuration)
        {
            _configuration = configuration;
        }

        public IConnection GetConnection()
        {
            if (_connection != null && _connection.IsOpen)
            {
                return _connection;
            }

            lock (_syncRoot)
            {
                if (_connection != null && _connection.IsOpen)
                {
                    return _connection;
                }

                var section = _configuration.GetSection("RabbitMQ");
                var factory = new ConnectionFactory
                {
                    HostName = section["HostName"] ?? "localhost",
                    UserName = section["UserName"] ?? "guest",
                    Password = section["Password"] ?? "guest",
                    Port = int.TryParse(section["Port"], out var port) ? port : 5672,
                    DispatchConsumersAsync = true
                };

                _connection = factory.CreateConnection();
                return _connection;
            }
        }

        public void Dispose()
        {
            try { _connection?.Dispose(); } catch { /* ignore */ }
        }
    }
}