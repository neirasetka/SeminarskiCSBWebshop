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
                })
                .Build()
                .Run();
        }
    }
}
