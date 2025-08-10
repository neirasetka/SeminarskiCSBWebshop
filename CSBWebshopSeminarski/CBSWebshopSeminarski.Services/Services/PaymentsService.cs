using AutoMapper;
using CBSWebshopSeminarski.Services.Interfaces;
using CSBWebshopSeminarski.Core.Entities;
using CSBWebshopSeminarski.Database;
using Microsoft.EntityFrameworkCore;

namespace CBSWebshopSeminarski.Services.Services
{
    public class PaymentsService : IPaymentsService
    {
        private readonly CocoSunBagsWebshopDbContext _db;

        public PaymentsService(CocoSunBagsWebshopDbContext db)
        {
            _db = db;
        }

        public async Task HandlePaymentSucceededAsync(string paymentIntentId, IDictionary<string, string> metadata)
        {
            var orderId = metadata.TryGetValue("order_id", out var idStr) && int.TryParse(idStr, out var id) ? id : 0;
            if (orderId == 0)
            {
                return;
            }

            // Idempotency: skip if we already recorded this payment
            var alreadyExists = await _db.Purchases.AnyAsync(p => p.StripeId == paymentIntentId);
            if (alreadyExists)
            {
                return;
            }

            var order = await _db.Orders.Include(o => o.User).FirstOrDefaultAsync(o => o.OrderID == orderId);
            if (order == null)
            {
                return;
            }

            var purchase = new Purchases
            {
                OrderID = order.OrderID,
                OrderNumber = order.OrderNumber,
                Price = order.Price,
                PurchaseDate = DateTime.UtcNow,
                UserID = order.UserID,
                Username = order.User?.UserName ?? string.Empty,
                StripeId = paymentIntentId
            };

            _db.Purchases.Add(purchase);
            await _db.SaveChangesAsync();
        }

        public async Task HandlePaymentFailedAsync(string paymentIntentId, IDictionary<string, string> metadata, string failureMessage)
        {
            // For now just no-op; could log failure or mark order as payment_failed if that field exists
            await Task.CompletedTask;
        }
    }
}