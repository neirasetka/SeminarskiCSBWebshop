using CBSWebshopSeminarski.Services.Interfaces;
using CSBWebshopSeminarski.Core.Entities;
using CSBWebshopSeminarski.Database;
using Microsoft.EntityFrameworkCore;

namespace CSBWebshopSeminarski
{
    public class ShippingStatusRefreshWorker : BackgroundService
    {
        private readonly IServiceProvider _services;
        private readonly ILogger<ShippingStatusRefreshWorker> _logger;
        private readonly TimeSpan _interval = TimeSpan.FromMinutes(15);

        public ShippingStatusRefreshWorker(IServiceProvider services, ILogger<ShippingStatusRefreshWorker> logger)
        {
            _services = services;
            _logger = logger;
        }

        protected override async Task ExecuteAsync(CancellationToken stoppingToken)
        {
            // simple periodic loop
            while (!stoppingToken.IsCancellationRequested)
            {
                try
                {
                    using var scope = _services.CreateScope();
                    var db = scope.ServiceProvider.GetRequiredService<CocoSunBagsWebshopDbContext>();
                    var tracking = scope.ServiceProvider.GetRequiredService<IShipmentTrackingService>();

                    var candidates = await db.Orders
                        .Where(o => o.ShippingStatus == ShippingStatus.Shipped
                                 || o.ShippingStatus == ShippingStatus.InTransit
                                 || o.ShippingStatus == ShippingStatus.AtCustoms
                                 || o.ShippingStatus == ShippingStatus.OutForDelivery)
                        .Select(o => o.OrderID)
                        .ToListAsync(stoppingToken);

                    foreach (var orderId in candidates)
                    {
                        try { await tracking.RefreshFromCarrierAsync(orderId); }
                        catch (Exception ex) { _logger.LogWarning(ex, "Refresh failed for order {OrderId}", orderId); }
                    }
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex, "ShippingStatusRefreshWorker loop error");
                }

                await Task.Delay(_interval, stoppingToken);
            }
        }
    }
}