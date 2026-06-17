using CBSWebshopSeminarski.Services.Services;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;

namespace CBSWebshopSeminarski.Services.RabbitMq;

public static class RabbitMqServiceCollectionExtensions
{
    /// <summary>
    /// Registrira dijeljenu RabbitMQ konekciju, channel pool i mail publisher.
    /// </summary>
    public static IServiceCollection AddRabbitMqMailInfrastructure(
        this IServiceCollection services,
        string connectionClientName = "CSB Mail Client",
        int channelPoolSize = 2)
    {
        services.AddSingleton<IRabbitMqConnectionProvider>(sp =>
            new RabbitMqConnectionProvider(
                sp.GetRequiredService<IConfiguration>(),
                sp.GetRequiredService<ILogger<RabbitMqConnectionProvider>>(),
                connectionClientName));

        services.AddSingleton<IRabbitMqChannelPool>(sp =>
            new RabbitMqChannelPool(
                sp.GetRequiredService<IRabbitMqConnectionProvider>(),
                sp.GetRequiredService<IConfiguration>(),
                sp.GetRequiredService<ILogger<RabbitMqChannelPool>>(),
                channelPoolSize));

        services.AddSingleton<RabbitMqMailPublisher>();
        return services;
    }

    /// <summary>
    /// Samo dijeljena konekcija — za Notifications worker (consumer drži vlastiti channel).
    /// </summary>
    public static IServiceCollection AddRabbitMqConnection(
        this IServiceCollection services,
        string connectionClientName = "CSB Mail Consumer")
    {
        services.AddSingleton<IRabbitMqConnectionProvider>(sp =>
            new RabbitMqConnectionProvider(
                sp.GetRequiredService<IConfiguration>(),
                sp.GetRequiredService<ILogger<RabbitMqConnectionProvider>>(),
                connectionClientName));
        return services;
    }
}
