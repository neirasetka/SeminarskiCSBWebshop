using CBSWebshopSeminarski.Services.Interfaces;
using CBSWebshopSeminarski.Services.StateMachines;
using CBSWebshopSeminarski.Services;
using CSBWebshopSeminarski.Core.Entities;
using CSBWebshopSeminarski.Database;
using Microsoft.Extensions.Logging;
using Microsoft.EntityFrameworkCore;

namespace CBSWebshopSeminarski.Services.Services
{
    public class PaymentsService : IPaymentsService
    {
        private readonly CocoSunBagsWebshopDbContext _db;
        private readonly RabbitMqMailPublisher _mailPublisher;
        private readonly ILogger<PaymentsService> _logger;
        private readonly IInAppNotificationService _inAppNotifications;

        public PaymentsService(
            CocoSunBagsWebshopDbContext db,
            RabbitMqMailPublisher mailPublisher,
            ILogger<PaymentsService> logger,
            IInAppNotificationService inAppNotifications)
        {
            _db = db;
            _mailPublisher = mailPublisher;
            _logger = logger;
            _inAppNotifications = inAppNotifications;
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

            var orderAlreadyPaid = await _db.Purchases.AnyAsync(p => p.OrderID == orderId);
            if (orderAlreadyPaid)
            {
                _logger.LogWarning("Payment succeeded event for order {OrderId} but a purchase already exists. Skipping.", orderId);
                return;
            }

            var order = await _db.Orders.Include(o => o.User).FirstOrDefaultAsync(o => o.OrderID == orderId);
            if (order == null)
            {
                return;
            }

            if (order.PaymentStatus == PaymentStatus.Paid)
            {
                _logger.LogWarning(
                    "Payment succeeded event for order {OrderId} but payment status is already Paid. Skipping purchase creation.",
                    orderId);
                return;
            }

            OrderStateMachine.ValidatePaymentTransition(order.PaymentStatus, PaymentStatus.Paid);
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

            await _inAppNotifications.CreateAsync(
                order.UserID,
                InAppNotificationTypes.OrderPaid,
                "Plaćanje potvrđeno",
                $"Uspješno plaćena narudžba #{order.OrderNumber}.",
                order.OrderID);

            var receiptEmail = metadata.TryGetValue("receipt_email", out var email) && !string.IsNullOrWhiteSpace(email)
                ? email.Trim()
                : null;
            await SendPaymentConfirmationIfNotSentYetAsync(order.OrderID, receiptEmail);
        }

        public async Task SendPaymentConfirmationIfNotSentYetAsync(int orderId, string? receiptEmailOverride)
        {
            var order = await _db.Orders.Include(o => o.User).FirstOrDefaultAsync(o => o.OrderID == orderId);
            if (order == null)
            {
                _logger.LogWarning("Payment confirmation email skipped: order {OrderId} not found.", orderId);
                return;
            }
            if (order.PaymentStatus != PaymentStatus.Paid)
            {
                _logger.LogInformation(
                    "Payment confirmation email skipped: order {OrderId} status is {Status}, expected Paid.",
                    orderId,
                    order.PaymentStatus);
                return;
            }
            if (order.PaymentConfirmationEmailSent)
            {
                _logger.LogInformation(
                    "Payment confirmation email skipped: already sent for order {OrderId}.",
                    orderId);
                return;
            }

            var to = !string.IsNullOrWhiteSpace(receiptEmailOverride)
                ? receiptEmailOverride.Trim()
                : order.User?.Email;
            if (string.IsNullOrWhiteSpace(to))
            {
                _logger.LogWarning(
                    "Payment confirmation email skipped: no recipient email for order {OrderId}.",
                    orderId);
                return;
            }

            try
            {
                var subject = $"Potvrda plaćanja — narudžba #{order.OrderNumber}";
                var message = "Poštovani/a,\n\n" +
                    "Uspješno smo zaprimili Vaše plaćanje.\n\n" +
                    $"Broj narudžbe: {order.OrderNumber}\n" +
                    $"Ukupan iznos: {order.Price:N2} KM\n\n" +
                    "Hvala Vam na povjerenju.\n\n" +
                    "CocoSunBags tim";
                _mailPublisher.Publish(
                    sender: "no-reply@cocosunbags.local",
                    recipient: to,
                    subject: subject,
                    content: message);
                order.PaymentConfirmationEmailSent = true;
                await _db.SaveChangesAsync();
                _logger.LogInformation(
                    "Payment confirmation email queued for order {OrderId} to {Recipient}.",
                    orderId,
                    to);
            }
            catch (Exception ex)
            {
                // Order stays paid; email can be retried from another path if needed.
                _logger.LogError(
                    ex,
                    "Payment confirmation email queue publish failed for order {OrderId} to {Recipient}.",
                    orderId,
                    to);
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
                    OrderStateMachine.ValidatePaymentTransition(order.PaymentStatus, PaymentStatus.Failed);
                    order.PaymentStatus = PaymentStatus.Failed;
                    order.StripePaymentIntentId = null;
                    order.StripeCheckoutSessionId = null;
                    await _db.SaveChangesAsync();
                }
            }
            await Task.CompletedTask;
        }
    }
}
