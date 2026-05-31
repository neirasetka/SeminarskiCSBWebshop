using CBSWebshopSeminarski.Model.Requests;
using CBSWebshopSeminarski.Services.Interfaces;
using CBSWebshopSeminarski.Services.StateMachines;
using CSBWebshopSeminarski.Core.Entities;
using CSBWebshopSeminarski.Database;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using Stripe;
using Stripe.Checkout;

using CBSWebshopSeminarski.Services;
using CBSWebshopSeminarski.Services.Exceptions;

namespace CBSWebshopSeminarski.Services.Services
{
    public class PaymentsService : IPaymentsService
    {
        private readonly CocoSunBagsWebshopDbContext _db;
        private readonly RabbitMqMailPublisher _mailPublisher;
        private readonly ILogger<PaymentsService> _logger;
        private readonly IInAppNotificationService _inAppNotifications;
        private readonly IConfiguration _configuration;

        private static readonly string[] DefaultAllowedRedirectHosts =
        {
            "localhost", "127.0.0.1", "cocosunbags.local", "checkout.csb.local"
        };

        private const string DefaultPaymentCurrency = "bam";
        private const long MinimumAmountInMinorUnits = 50;

        private static readonly HashSet<string> ActivePaymentIntentStatuses = new(StringComparer.OrdinalIgnoreCase)
        {
            "requires_payment_method",
            "requires_confirmation",
            "requires_action",
            "processing",
            "requires_capture"
        };

        public PaymentsService(
            CocoSunBagsWebshopDbContext db,
            RabbitMqMailPublisher mailPublisher,
            ILogger<PaymentsService> logger,
            IInAppNotificationService inAppNotifications,
            IConfiguration configuration)
        {
            _db = db;
            _mailPublisher = mailPublisher;
            _logger = logger;
            _inAppNotifications = inAppNotifications;
            _configuration = configuration;
        }

        public StripeConfigResponse GetStripeConfig()
        {
            return new StripeConfigResponse
            {
                PublishableKey = _configuration["Stripe:PublishableKey"] ?? string.Empty,
                Currency = GetPaymentCurrency(),
                CurrencyDisplay = _configuration["Stripe:CurrencyDisplay"]?.Trim() is { Length: > 0 } d ? d : "KM"
            };
        }

        public async Task<CreatePaymentIntentResponse> CreatePaymentIntentAsync(
            CreatePaymentIntentRequest request,
            int? currentUserId,
            bool isAdmin)
        {
            var order = await _db.Orders.FindAsync(request.OrderID)
                ?? throw new NotFoundException("Order not found");

            EnsureOrderAccess(order, currentUserId, isAdmin);

            var validationError = await ValidateOrderForPaymentAsync(order);
            if (validationError != null)
                throw new BusinessException(validationError);

            var (amountInCents, calcError) = await CalculateOrderTotalAsync(order.OrderID);
            if (calcError != null)
                throw new BusinessException(calcError);

            var currency = GetPaymentCurrency();
            var existingPayment = await GetExistingStripePaymentAsync(order);
            if (existingPayment.Error != null)
                throw new BusinessException(existingPayment.Error);

            if (existingPayment.ActiveCheckoutSession != null)
                throw new ConflictException("An active checkout session is already in progress for this order.");

            if (existingPayment.ActivePaymentIntent != null)
            {
                var activeIntent = existingPayment.ActivePaymentIntent;
                if (activeIntent.Amount != amountInCents
                    || !string.Equals(activeIntent.Currency, currency, StringComparison.OrdinalIgnoreCase))
                {
                    throw new ConflictException("Active payment amount does not match the current order total.");
                }

                return new CreatePaymentIntentResponse
                {
                    ClientSecret = activeIntent.ClientSecret,
                    PaymentIntentId = activeIntent.Id
                };
            }

            var metadata = GetCheckoutMetadata(order.OrderID, order.OrderNumber, order.UserID, request.ReceiptEmail);

            var paymentIntentService = new PaymentIntentService();
            var createOptions = new PaymentIntentCreateOptions
            {
                Amount = amountInCents,
                Currency = currency,
                Metadata = metadata,
                ReceiptEmail = request.ReceiptEmail,
                AutomaticPaymentMethods = new PaymentIntentAutomaticPaymentMethodsOptions
                {
                    Enabled = true
                }
            };

            var intent = await paymentIntentService.CreateAsync(
                createOptions,
                new RequestOptions { IdempotencyKey = $"order-{order.OrderID}-pi" });

            order.StripePaymentIntentId = intent.Id;
            await _db.SaveChangesAsync();

            return new CreatePaymentIntentResponse
            {
                ClientSecret = intent.ClientSecret,
                PaymentIntentId = intent.Id
            };
        }

        public async Task<CreateCheckoutSessionResponse> CreateCheckoutSessionAsync(
            CreateCheckoutSessionRequest request,
            int? currentUserId,
            bool isAdmin,
            CheckoutRedirectContext redirectContext)
        {
            var order = await _db.Orders.Include(o => o.OrderItems).FirstOrDefaultAsync(o => o.OrderID == request.OrderID)
                ?? throw new NotFoundException("Order not found");

            EnsureOrderAccess(order, currentUserId, isAdmin);

            var validationError = await ValidateOrderForPaymentAsync(order);
            if (validationError != null)
                throw new BusinessException(validationError);

            var (amountInCents, calcError) = await CalculateOrderTotalAsync(order.OrderID);
            if (calcError != null)
                throw new BusinessException(calcError);

            var (successUrl, cancelUrl, successPrefix) = ResolveCheckoutRedirectUrls(redirectContext);

            var currency = GetPaymentCurrency();
            var existingPayment = await GetExistingStripePaymentAsync(order);
            if (existingPayment.Error != null)
                throw new BusinessException(existingPayment.Error);

            if (existingPayment.ActivePaymentIntent != null)
                throw new ConflictException("An active payment intent is already in progress for this order.");

            if (existingPayment.ActiveCheckoutSession != null)
            {
                var activeSession = existingPayment.ActiveCheckoutSession;
                if (activeSession.AmountTotal.HasValue && activeSession.AmountTotal.Value != amountInCents)
                    throw new ConflictException("Active checkout amount does not match the current order total.");

                return new CreateCheckoutSessionResponse
                {
                    Url = activeSession.Url ?? string.Empty,
                    SessionId = activeSession.Id,
                    SuccessRedirectUrl = successPrefix,
                    CancelRedirectUrl = cancelUrl
                };
            }

            var sessionService = new SessionService();
            var createOptions = new SessionCreateOptions
            {
                Mode = "payment",
                SuccessUrl = successUrl,
                CancelUrl = cancelUrl,
                LineItems = new List<SessionLineItemOptions>
                {
                    new()
                    {
                        PriceData = new SessionLineItemPriceDataOptions
                        {
                            Currency = currency,
                            UnitAmount = amountInCents,
                            ProductData = new SessionLineItemPriceDataProductDataOptions
                            {
                                Name = $"Narudžba #{order.OrderNumber}",
                                Description = $"CSB Webshop - {order.OrderItems.Count} stavki",
                            }
                        },
                        Quantity = 1
                    }
                },
                PaymentIntentData = new SessionPaymentIntentDataOptions
                {
                    Metadata = GetCheckoutMetadata(order.OrderID, order.OrderNumber, order.UserID, request.ReceiptEmail)
                }
            };

            if (!string.IsNullOrWhiteSpace(request.ReceiptEmail))
            {
                createOptions.CustomerEmail = request.ReceiptEmail;
            }

            var session = await sessionService.CreateAsync(
                createOptions,
                new RequestOptions { IdempotencyKey = $"order-{order.OrderID}-cs" });

            order.StripeCheckoutSessionId = session.Id;
            if (!string.IsNullOrWhiteSpace(session.PaymentIntentId))
                order.StripePaymentIntentId = session.PaymentIntentId;

            if (order.ShippingStatus == ShippingStatus.Pending)
            {
                ShippingStateMachine.ValidateTransition(order.ShippingStatus, ShippingStatus.Processing);
                order.ShippingStatus = ShippingStatus.Processing;
                order.LastStatusUpdate = DateTime.UtcNow;
                await _db.SaveChangesAsync();
            }

            return new CreateCheckoutSessionResponse
            {
                Url = session.Url ?? string.Empty,
                SessionId = session.Id,
                SuccessRedirectUrl = successPrefix,
                CancelRedirectUrl = cancelUrl
            };
        }

        public async Task<PaymentConfirmResult> ConfirmCheckoutSessionAsync(
            string sessionId,
            int? orderId,
            int? currentUserId,
            bool isAdmin)
        {
            if (string.IsNullOrWhiteSpace(sessionId))
                throw new ValidationException("SessionId is required.");

            var sessionService = new SessionService();
            Session session;
            try
            {
                session = await sessionService.GetAsync(sessionId, new SessionGetOptions
                {
                    Expand = new List<string> { "payment_intent" }
                });
            }
            catch (StripeException ex)
            {
                throw new BusinessException($"Stripe session lookup failed: {ex.Message}");
            }

            var paymentIntentId = session.PaymentIntentId;
            if (string.IsNullOrWhiteSpace(paymentIntentId) && session.PaymentIntent is PaymentIntent piObj)
            {
                paymentIntentId = piObj.Id;
            }

            if (string.IsNullOrWhiteSpace(paymentIntentId))
            {
                return new PaymentConfirmResult { Paid = false, Reason = "payment_intent_missing" };
            }

            var paymentIntentService = new PaymentIntentService();
            PaymentIntent paymentIntent;
            try
            {
                paymentIntent = await paymentIntentService.GetAsync(paymentIntentId);
            }
            catch (StripeException ex)
            {
                throw new BusinessException($"Stripe payment intent lookup failed: {ex.Message}");
            }

            return await ConfirmPaidPaymentIntentAsync(paymentIntent, session.PaymentStatus, orderId, currentUserId, isAdmin);
        }

        public async Task<PaymentConfirmResult> ConfirmPaymentIntentAsync(
            string paymentIntentId,
            int? orderId,
            int? currentUserId,
            bool isAdmin)
        {
            if (string.IsNullOrWhiteSpace(paymentIntentId))
                throw new ValidationException("PaymentIntentId is required.");

            var paymentIntentService = new PaymentIntentService();
            PaymentIntent paymentIntent;
            try
            {
                paymentIntent = await paymentIntentService.GetAsync(paymentIntentId);
            }
            catch (StripeException ex)
            {
                throw new BusinessException($"Stripe payment intent lookup failed: {ex.Message}");
            }

            if (paymentIntent == null)
                throw new NotFoundException("Payment intent not found.");

            return await ConfirmPaidPaymentIntentAsync(paymentIntent, null, orderId, currentUserId, isAdmin);
        }

        public async Task<PaymentConfirmResult> ReconcileOrderPaymentAsync(int orderId)
        {
            var order = await _db.Orders.FirstOrDefaultAsync(o => o.OrderID == orderId)
                ?? throw new NotFoundException("Order not found.");

            if (await _db.Purchases.AnyAsync(p => p.OrderID == orderId))
            {
                return new PaymentConfirmResult
                {
                    Paid = true,
                    OrderId = orderId,
                    Reason = "already_recorded"
                };
            }

            if (!string.IsNullOrWhiteSpace(order.StripeCheckoutSessionId))
            {
                return await ConfirmCheckoutSessionAsync(
                    order.StripeCheckoutSessionId,
                    orderId,
                    currentUserId: null,
                    isAdmin: true);
            }

            if (!string.IsNullOrWhiteSpace(order.StripePaymentIntentId))
            {
                return await ConfirmPaymentIntentAsync(
                    order.StripePaymentIntentId,
                    orderId,
                    currentUserId: null,
                    isAdmin: true);
            }

            throw new BusinessException(
                "Order has no Stripe checkout session or payment intent. Payment cannot be reconciled.");
        }

        public async Task HandlePaymentSucceededAsync(string paymentIntentId, IDictionary<string, string> metadata)
        {
            var orderId = metadata.TryGetValue("order_id", out var idStr) && int.TryParse(idStr, out var id) ? id : 0;
            if (orderId == 0)
            {
                return;
            }

            PaymentIntent paymentIntent;
            try
            {
                paymentIntent = await new PaymentIntentService().GetAsync(paymentIntentId);
            }
            catch (StripeException ex)
            {
                _logger.LogError(
                    ex,
                    "Stripe payment intent lookup failed for {PaymentIntentId} (order {OrderId}).",
                    paymentIntentId,
                    orderId);
                throw;
            }

            await HandlePaymentSucceededAsync(paymentIntent, metadata);
        }

        private async Task<bool> HandlePaymentSucceededAsync(PaymentIntent paymentIntent, IDictionary<string, string> metadata)
        {
            var paymentIntentId = paymentIntent.Id;
            var orderId = metadata.TryGetValue("order_id", out var idStr) && int.TryParse(idStr, out var id) ? id : 0;
            if (orderId == 0)
            {
                return false;
            }

            var alreadyExists = await _db.Purchases.AnyAsync(p => p.StripeId == paymentIntentId);
            if (alreadyExists)
            {
                return true;
            }

            var orderAlreadyPaid = await _db.Purchases.AnyAsync(p => p.OrderID == orderId);
            if (orderAlreadyPaid)
            {
                _logger.LogWarning("Payment succeeded event for order {OrderId} but a purchase already exists. Skipping.", orderId);
                return true;
            }

            var order = await _db.Orders.Include(o => o.User).FirstOrDefaultAsync(o => o.OrderID == orderId);
            if (order == null)
            {
                return false;
            }

            if (!await PaymentIntentMatchesOrderTotalAsync(orderId, paymentIntent))
            {
                return false;
            }

            var wasAlreadyPaid = order.PaymentStatus == PaymentStatus.Paid;
            if (!wasAlreadyPaid)
            {
                OrderStateMachine.ValidatePaymentTransition(order.PaymentStatus, PaymentStatus.Paid);
                order.PaymentStatus = PaymentStatus.Paid;
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

            await _db.ExecuteInTransactionAsync(async () =>
            {
                _db.Purchases.Add(purchase);
                if (!wasAlreadyPaid)
                {
                    _inAppNotifications.StageCreate(
                        order.UserID,
                        InAppNotificationTypes.OrderPaid,
                        "Plaćanje potvrđeno",
                        $"Uspješno plaćena narudžba #{order.OrderNumber}.",
                        order.OrderID);
                }
                await _db.SaveChangesAsync();
            });

            var receiptEmail = metadata.TryGetValue("receipt_email", out var email) && !string.IsNullOrWhiteSpace(email)
                ? email.Trim()
                : null;
            await SendPaymentConfirmationIfNotSentYetAsync(order.OrderID, receiptEmail);
            return true;
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

        private async Task<PaymentConfirmResult> ConfirmPaidPaymentIntentAsync(
            PaymentIntent paymentIntent,
            string? sessionPaymentStatus,
            int? requestedOrderId,
            int? currentUserId,
            bool isAdmin)
        {
            var metadata = paymentIntent.Metadata != null
                ? new Dictionary<string, string>(paymentIntent.Metadata)
                : new Dictionary<string, string>();

            if (!metadata.TryGetValue("order_id", out var metadataOrderId))
            {
                return new PaymentConfirmResult { Paid = false, Reason = "order_id_missing_in_metadata" };
            }

            if (!int.TryParse(metadataOrderId, out var orderIdFromMetadata))
            {
                return new PaymentConfirmResult { Paid = false, Reason = "invalid_order_id_metadata" };
            }

            var order = await _db.Orders.FirstOrDefaultAsync(o => o.OrderID == orderIdFromMetadata)
                ?? throw new NotFoundException("Order not found.");

            EnsureOrderAccess(order, currentUserId, isAdmin);

            if (requestedOrderId.HasValue && requestedOrderId.Value != order.OrderID)
                throw new BusinessException("Payment does not belong to provided order.");

            var isPaid = string.Equals(paymentIntent.Status, "succeeded", StringComparison.OrdinalIgnoreCase)
                         || string.Equals(sessionPaymentStatus, "paid", StringComparison.OrdinalIgnoreCase);

            if (isPaid)
            {
                var recorded = await HandlePaymentSucceededAsync(paymentIntent, metadata);
                return new PaymentConfirmResult
                {
                    Paid = recorded,
                    OrderId = order.OrderID,
                    PaymentIntentId = paymentIntent.Id,
                    Status = paymentIntent.Status,
                    Reason = recorded ? null : "payment_amount_mismatch"
                };
            }

            return new PaymentConfirmResult
            {
                Paid = false,
                OrderId = order.OrderID,
                Status = paymentIntent.Status
            };
        }

        private static void EnsureOrderAccess(Orders order, int? currentUserId, bool isAdmin)
        {
            if (isAdmin)
                return;

            if (!currentUserId.HasValue || order.UserID != currentUserId.Value)
                throw new ForbiddenException("Access denied.");
        }

        private string GetPaymentCurrency() =>
            !string.IsNullOrWhiteSpace(_configuration["Stripe:Currency"])
                ? _configuration["Stripe:Currency"]!.Trim().ToLowerInvariant()
                : DefaultPaymentCurrency;

        private bool IsRedirectUrlAllowed(string url)
        {
            if (!Uri.TryCreate(url, UriKind.Absolute, out var uri)) return false;

            var configuredHosts = _configuration.GetSection("Stripe:AllowedRedirectHosts").Get<string[]>();
            var allowedHosts = configuredHosts is { Length: > 0 } ? configuredHosts : DefaultAllowedRedirectHosts;

            return allowedHosts.Any(h =>
                       string.Equals(uri.Host, h, StringComparison.OrdinalIgnoreCase))
                   || uri.Host.EndsWith(".cocosunbags.local", StringComparison.OrdinalIgnoreCase);
        }

        private static string GetSuccessRedirectPrefix(string successUrlTemplate)
        {
            var withoutPlaceholder = successUrlTemplate
                .Replace("{CHECKOUT_SESSION_ID}", string.Empty, StringComparison.Ordinal)
                .TrimEnd('?', '&', '=');
            return withoutPlaceholder.TrimEnd('/');
        }

        private (string successUrl, string cancelUrl, string successPrefix) ResolveCheckoutRedirectUrls(CheckoutRedirectContext redirectContext)
        {
            var configuredSuccess = _configuration["Stripe:CheckoutSuccessUrl"]?.Trim();
            var configuredCancel = _configuration["Stripe:CheckoutCancelUrl"]?.Trim();

            if (!string.IsNullOrWhiteSpace(configuredSuccess)
                && !string.IsNullOrWhiteSpace(configuredCancel)
                && IsRedirectUrlAllowed(configuredSuccess)
                && IsRedirectUrlAllowed(configuredCancel))
            {
                var successUrl = configuredSuccess.Contains("{CHECKOUT_SESSION_ID}", StringComparison.Ordinal)
                    ? configuredSuccess
                    : $"{configuredSuccess}{(configuredSuccess.Contains('?') ? "&" : "?")}session_id={{CHECKOUT_SESSION_ID}}";
                return (successUrl, configuredCancel, GetSuccessRedirectPrefix(successUrl));
            }

            var baseUrl = $"{redirectContext.RequestScheme}://{redirectContext.RequestHost}";
            var fallbackSuccess = $"{baseUrl}/checkout-success?session_id={{CHECKOUT_SESSION_ID}}";
            var fallbackCancel = $"{baseUrl}/checkout-cancel";
            return (fallbackSuccess, fallbackCancel, GetSuccessRedirectPrefix(fallbackSuccess));
        }

        private static Dictionary<string, string> GetCheckoutMetadata(int orderId, string orderNumber, int userId, string? receiptEmail)
        {
            var metadata = new Dictionary<string, string>
            {
                { "order_id", orderId.ToString() },
                { "order_number", orderNumber },
                { "user_id", userId.ToString() }
            };
            if (!string.IsNullOrWhiteSpace(receiptEmail))
            {
                metadata["receipt_email"] = receiptEmail;
            }
            return metadata;
        }

        private async Task<bool> PaymentIntentMatchesOrderTotalAsync(int orderId, PaymentIntent paymentIntent)
        {
            if (!string.Equals(paymentIntent.Status, "succeeded", StringComparison.OrdinalIgnoreCase))
            {
                _logger.LogWarning(
                    "Payment intent {PaymentIntentId} for order {OrderId} has status {Status}, expected succeeded. Skipping.",
                    paymentIntent.Id,
                    orderId,
                    paymentIntent.Status);
                return false;
            }

            var (expectedCents, calcError) = await CalculateOrderTotalAsync(orderId);
            if (calcError != null)
            {
                _logger.LogWarning(
                    "Cannot verify payment amount for order {OrderId}: {Error}. Payment intent {PaymentIntentId}. Skipping.",
                    orderId,
                    calcError,
                    paymentIntent.Id);
                return false;
            }

            var currency = GetPaymentCurrency();
            if (paymentIntent.Amount != expectedCents
                || !string.Equals(paymentIntent.Currency, currency, StringComparison.OrdinalIgnoreCase))
            {
                _logger.LogWarning(
                    "Payment amount mismatch for order {OrderId}. Stripe charged {StripeAmount} {StripeCurrency}, expected {ExpectedAmount} {ExpectedCurrency}. Payment intent {PaymentIntentId}. Skipping.",
                    orderId,
                    paymentIntent.Amount,
                    paymentIntent.Currency,
                    expectedCents,
                    currency,
                    paymentIntent.Id);
                return false;
            }

            return true;
        }

        private async Task<(long amountInCents, string? error)> CalculateOrderTotalAsync(int orderId)
        {
            var orderItems = await _db.OrderItems
                .Where(oi => oi.OrderID == orderId)
                .Include(oi => oi.Bag)
                .Include(oi => oi.Belt)
                .ToListAsync();

            if (!orderItems.Any())
                return (0, "Order has no items.");

            decimal total = 0m;
            foreach (var item in orderItems)
            {
                decimal unitPrice = 0m;
                if (item.Price.HasValue && item.Price.Value > 0)
                    unitPrice = (decimal)item.Price.Value;
                else if (item.Bag != null)
                    unitPrice = (decimal)item.Bag.Price;
                else if (item.Belt != null)
                    unitPrice = (decimal)item.Belt.Price;

                var qty = item.Quantity ?? 1;
                var discount = item.Discount ?? 0m;
                var lineTotal = unitPrice * qty * (1 - discount / 100m);
                total += lineTotal;
            }

            var cents = (long)Math.Round(total * 100m);
            if (cents < MinimumAmountInMinorUnits)
                return (0, "Order total is too small for payment (minimum 0.50 KM).");
            return (cents, null);
        }

        private async Task<string?> ValidateOrderForPaymentAsync(Orders order)
        {
            if (order.PaymentStatus != PaymentStatus.Pending)
                return $"Order payment status is {order.PaymentStatus}, expected Pending.";

            if (order.ShippingStatus == ShippingStatus.Cancelled)
                return "Order has been cancelled.";

            var hasItems = await _db.OrderItems.AnyAsync(oi => oi.OrderID == order.OrderID);
            if (!hasItems)
                return "Order has no items.";

            var alreadyPaid = await _db.Purchases.AnyAsync(p => p.OrderID == order.OrderID);
            if (alreadyPaid)
                return "Order has already been paid.";

            return null;
        }

        private sealed record ExistingStripePaymentCheck(
            string? Error,
            PaymentIntent? ActivePaymentIntent,
            Session? ActiveCheckoutSession);

        private async Task ClearStaleStripeReferenceAsync(Orders order, bool paymentIntent, bool checkoutSession)
        {
            if (paymentIntent)
                order.StripePaymentIntentId = null;
            if (checkoutSession)
                order.StripeCheckoutSessionId = null;
            await _db.SaveChangesAsync();
        }

        private async Task<ExistingStripePaymentCheck> GetExistingStripePaymentAsync(Orders order)
        {
            PaymentIntent? activePaymentIntent = null;
            Session? activeCheckoutSession = null;

            if (!string.IsNullOrWhiteSpace(order.StripePaymentIntentId))
            {
                try
                {
                    var paymentIntent = await new PaymentIntentService().GetAsync(order.StripePaymentIntentId);
                    if (string.Equals(paymentIntent.Status, "succeeded", StringComparison.OrdinalIgnoreCase))
                        return new ExistingStripePaymentCheck("Order has already been paid.", null, null);

                    if (ActivePaymentIntentStatuses.Contains(paymentIntent.Status))
                        activePaymentIntent = paymentIntent;
                }
                catch (StripeException)
                {
                    await ClearStaleStripeReferenceAsync(order, paymentIntent: true, checkoutSession: false);
                }
            }

            if (!string.IsNullOrWhiteSpace(order.StripeCheckoutSessionId))
            {
                try
                {
                    var checkoutSession = await new SessionService().GetAsync(order.StripeCheckoutSessionId);
                    if (string.Equals(checkoutSession.Status, "complete", StringComparison.OrdinalIgnoreCase)
                        || string.Equals(checkoutSession.PaymentStatus, "paid", StringComparison.OrdinalIgnoreCase))
                        return new ExistingStripePaymentCheck("Order has already been paid.", null, null);

                    if (string.Equals(checkoutSession.Status, "open", StringComparison.OrdinalIgnoreCase))
                        activeCheckoutSession = checkoutSession;
                }
                catch (StripeException)
                {
                    await ClearStaleStripeReferenceAsync(order, paymentIntent: false, checkoutSession: true);
                }
            }

            return new ExistingStripePaymentCheck(null, activePaymentIntent, activeCheckoutSession);
        }
    }
}
