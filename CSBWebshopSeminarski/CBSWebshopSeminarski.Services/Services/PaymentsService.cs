using CBSWebshopSeminarski.Services.Interfaces;
using CSBWebshopSeminarski.Core.Entities;
using CSBWebshopSeminarski.Database;
using Microsoft.EntityFrameworkCore;

namespace CBSWebshopSeminarski.Services.Services
{
    public class PaymentsService : IPaymentsService
    {
        private readonly CocoSunBagsWebshopDbContext _db;
        private readonly EmailService _emailService;

        public PaymentsService(CocoSunBagsWebshopDbContext db, EmailService emailService)
        {
            _db = db;
            _emailService = emailService;
        }

        public async Task HandlePaymentSucceededAsync(string paymentIntentId, IDictionary<string, string> metadata)
        {
            var orderId = metadata.TryGetValue("order_id", out var idStr) && int.TryParse(idStr, out var id) ? id : 0;
            if (orderId == 0)
            {
                return;
            }

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

            // mark order as paid
            order.PaymentStatus = PaymentStatus.Paid;

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

            var receiptEmail = metadata.TryGetValue("receipt_email", out var email) && !string.IsNullOrWhiteSpace(email)
                ? email.Trim()
                : null;
            await SendPaymentConfirmationIfNotSentYetAsync(order.OrderID, receiptEmail);
        }

        public async Task SendPaymentConfirmationIfNotSentYetAsync(int orderId, string? receiptEmailOverride)
        {
            var order = await _db.Orders.Include(o => o.User).FirstOrDefaultAsync(o => o.OrderID == orderId);
            if (order == null || order.PaymentStatus != PaymentStatus.Paid || order.PaymentConfirmationEmailSent)
            {
                return;
            }

            var to = !string.IsNullOrWhiteSpace(receiptEmailOverride)
                ? receiptEmailOverride.Trim()
                : order.User?.Email;
            if (string.IsNullOrWhiteSpace(to))
            {
                return;
            }

            try
            {
                var subject = $"Potvrda plaćanja — narudžba #{order.OrderNumber}";
                var message = "Poštovani/a,\n\n" +
                    "Uspješno smo zaprimili Vaše plaćanje.\n\n" +
                    $"Broj narudžbe: {order.OrderNumber}\n" +
                    $"Ukupan iznos: {order.Price:N2} EUR\n\n" +
                    "Hvala Vam na povjerenju.\n\n" +
                    "CocoSunBags tim";
                await _emailService.SendEmailAsync(to, subject, message);
                order.PaymentConfirmationEmailSent = true;
                await _db.SaveChangesAsync();
            }
            catch
            {
                // Order stays paid; email can be retried from another path if needed
            }
        }

        public async Task HandlePaymentFailedAsync(string paymentIntentId, IDictionary<string, string> metadata, string failureMessage)
        {
            var orderId = metadata.TryGetValue("order_id", out var idStr) && int.TryParse(idStr, out var id) ? id : 0;
            if (orderId != 0)
            {
                var order = await _db.Orders.FirstOrDefaultAsync(o => o.OrderID == orderId);
                if (order != null)
                {
                    order.PaymentStatus = PaymentStatus.Failed;
                    await _db.SaveChangesAsync();
                }
            }
            await Task.CompletedTask;
        }
    }
}
