using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;

namespace CSBWebshopSeminarski.Notifications
{
    public class Program
    {
        public static void Main(string[] args)
        {
            Host.CreateDefaultBuilder(args)
                .ConfigureServices((context, services) =>
                {
                    services.AddHostedService<RabbitMqOrderCreatedConsumer>();
                    services.AddSingleton<CBSWebshopSeminarski.Services.Services.EmailService>(sp =>
                    {
                        var cfg = sp.GetRequiredService<IConfiguration>();
                        var host = cfg["Smtp:Host"] ?? string.Empty;
                        var port = int.TryParse(cfg["Smtp:Port"], out var p) ? p : 587;
                        var user = cfg["Smtp:User"] ?? string.Empty;
                        var pass = cfg["Smtp:Pass"] ?? string.Empty;
                        return new CBSWebshopSeminarski.Services.Services.EmailService(host, port, user, pass);
                    });
                })
                .Build()
                .Run();
        }
    }
}