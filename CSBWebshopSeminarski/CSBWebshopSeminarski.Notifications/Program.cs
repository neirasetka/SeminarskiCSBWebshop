using CBSWebshopSeminarski.Services.RabbitMq;

namespace CSBWebshopSeminarski.Notifications
{
    public class Program
    {
        public static void Main(string[] args)
        {
            Host.CreateDefaultBuilder(args)
                .ConfigureServices((context, services) =>
                {
                    services.AddRabbitMqConnection(connectionClientName: "CSB Mail Consumer");
                    services.AddHostedService<RabbitMqEmailConsumer>();
                })
                .Build()
                .Run();
        }
    }
}
