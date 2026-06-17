using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using RabbitMQ.Client;

namespace CBSWebshopSeminarski.Services.RabbitMq;

public sealed class RabbitMqChannelPool : IRabbitMqChannelPool
{
    private readonly IRabbitMqConnectionProvider _connectionProvider;
    private readonly IConfiguration _configuration;
    private readonly ILogger<RabbitMqChannelPool> _logger;
    private readonly int _maxPoolSize;
    private readonly object _sync = new();
    private readonly Stack<IModel> _available = new();
    private int _totalChannels;
    private bool _disposed;

    public RabbitMqChannelPool(
        IRabbitMqConnectionProvider connectionProvider,
        IConfiguration configuration,
        ILogger<RabbitMqChannelPool> logger,
        int maxPoolSize = 2)
    {
        _connectionProvider = connectionProvider;
        _configuration = configuration;
        _logger = logger;
        _maxPoolSize = Math.Max(1, maxPoolSize);
    }

    public IModel RentChannel()
    {
        ObjectDisposedException.ThrowIf(_disposed, this);

        lock (_sync)
        {
            while (_available.Count > 0)
            {
                var channel = _available.Pop();
                if (channel.IsOpen)
                    return channel;

                channel.Dispose();
                _totalChannels--;
            }

            var created = _connectionProvider.GetConnection().CreateModel();
            RabbitMqEmailTopology.Declare(created, _configuration);
            _totalChannels++;
            _logger.LogDebug(
                "RabbitMQ publish channel created (pool total {Total}, max {Max}).",
                _totalChannels,
                _maxPoolSize);
            return created;
        }
    }

    public void ReturnChannel(IModel channel)
    {
        if (channel == null)
            return;

        if (_disposed)
        {
            SafeDispose(channel);
            return;
        }

        lock (_sync)
        {
            if (_disposed)
            {
                SafeDispose(channel);
                return;
            }

            if (!channel.IsOpen)
            {
                SafeDispose(channel);
                _totalChannels--;
                return;
            }

            if (_available.Count < _maxPoolSize)
            {
                _available.Push(channel);
                return;
            }

            SafeDispose(channel);
            _totalChannels--;
        }
    }

    public void Dispose()
    {
        if (_disposed)
            return;

        _disposed = true;
        lock (_sync)
        {
            while (_available.Count > 0)
            {
                SafeDispose(_available.Pop());
            }

            _totalChannels = 0;
        }
    }

    private static void SafeDispose(IModel channel)
    {
        try
        {
            channel.Close();
            channel.Dispose();
        }
        catch
        {
            // ignore shutdown races
        }
    }
}
