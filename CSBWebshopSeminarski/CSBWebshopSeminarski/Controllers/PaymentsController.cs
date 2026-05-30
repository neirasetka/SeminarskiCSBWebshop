using CBSWebshopSeminarski.Model.Requests;
using CSBWebshopSeminarski.Database;
using CBSWebshopSeminarski.Services.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.EntityFrameworkCore;
using Microsoft.AspNetCore.Mvc;
using Stripe;
using Stripe.Checkout;
using System.Security.Claims;

namespace CSBWebshopSeminarski.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class PaymentsController : ControllerBase
    {
        private readonly CocoSunBagsWebshopDbContext _db;
        private readonly IPaymentsService _paymentsService;
        private readonly IConfiguration _configuration;

        public PaymentsController(CocoSunBagsWebshopDbContext db, IPaymentsService paymentsService, IConfiguration configuration)
        {
            _db = db;
            _paymentsService = paymentsService;
            _configuration = configuration;
        }

        public class StripeConfigResponse
        {
            public string PublishableKey { get; set; } = string.Empty;
            /// <summary>ISO 4217 code used for Stripe charges (default: bam).</summary>
            public string Currency { get; set; } = "bam";
            /// <summary>Display label shown in UI and emails (default: KM).</summary>
            public string CurrencyDisplay { get; set; } = "KM";
        }

        public class ConfirmCheckoutSessionRequest
        {
            public string SessionId { get; set; } = string.Empty;
            public int? OrderId { get; set; }
        }

        public class ConfirmPaymentIntentRequest
        {
            public string PaymentIntentId { get; set; } = string.Empty;
            public int? OrderId { get; set; }
        }

        private static readonly string[] DefaultAllowedRedirectHosts =
        {
            "localhost", "127.0.0.1", "cocosunbags.local", "checkout.csb.local"
        };

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

        private (string successUrl, string cancelUrl, string successPrefix) ResolveCheckoutRedirectUrls(HttpRequest httpRequest)
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

            var baseUrl = $"{httpRequest.Scheme}://{httpRequest.Host.Value}";
            var fallbackSuccess = $"{baseUrl}/checkout-success?session_id={{CHECKOUT_SESSION_ID}}";
            var fallbackCancel = $"{baseUrl}/checkout-cancel";
            return (fallbackSuccess, fallbackCancel, GetSuccessRedirectPrefix(fallbackSuccess));
        }

        private const string DefaultPaymentCurrency = "bam";
        private const long MinimumAmountInMinorUnits = 50; // 0.50 KM (Stripe minimum for BAM)

        private string GetPaymentCurrency() =>
            !string.IsNullOrWhiteSpace(_configuration["Stripe:Currency"])
                ? _configuration["Stripe:Currency"]!.Trim().ToLowerInvariant()
                : DefaultPaymentCurrency;

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

        private async Task<(long amountInCents, string? error)> CalculateOrderTotal(int orderId)
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
                if (item.Bag != null)
                    unitPrice = (decimal)item.Bag.Price;
                else if (item.Belt != null)
                    unitPrice = (decimal)item.Belt.Price;
                else if (item.Price.HasValue)
                    unitPrice = (decimal)item.Price.Value;

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

        private async Task<string?> ValidateOrderForPayment(CSBWebshopSeminarski.Core.Entities.Orders order)
        {
            if (order.PaymentStatus != CSBWebshopSeminarski.Core.Entities.PaymentStatus.Pending)
                return $"Order payment status is {order.PaymentStatus}, expected Pending.";

            if (order.ShippingStatus == CSBWebshopSeminarski.Core.Entities.ShippingStatus.Cancelled)
                return "Order has been cancelled.";

            var hasItems = await _db.OrderItems.AnyAsync(oi => oi.OrderID == order.OrderID);
            if (!hasItems)
                return "Order has no items.";

            var alreadyPaid = await _db.Purchases.AnyAsync(p => p.OrderID == order.OrderID);
            if (alreadyPaid)
                return "Order has already been paid.";

            return null;
        }

        private static readonly HashSet<string> ActivePaymentIntentStatuses = new(StringComparer.OrdinalIgnoreCase)
        {
            "requires_payment_method",
            "requires_confirmation",
            "requires_action",
            "processing",
            "requires_capture"
        };

        private sealed record ExistingStripePaymentCheck(
            string? Error,
            PaymentIntent? ActivePaymentIntent,
            Session? ActiveCheckoutSession);

        private async Task ClearStaleStripeReferenceAsync(CSBWebshopSeminarski.Core.Entities.Orders order, bool paymentIntent, bool checkoutSession)
        {
            if (paymentIntent)
                order.StripePaymentIntentId = null;
            if (checkoutSession)
                order.StripeCheckoutSessionId = null;
            await _db.SaveChangesAsync();
        }

        private async Task<ExistingStripePaymentCheck> GetExistingStripePaymentAsync(CSBWebshopSeminarski.Core.Entities.Orders order)
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

        [ProducesResponseType(typeof(CreatePaymentIntentResponse), StatusCodes.Status200OK)]
        [ProducesResponseType(StatusCodes.Status404NotFound)]
        [HttpPost("create-payment-intent")]
        [Authorize(Roles = "Buyer, Admin")]
        public async Task<ActionResult<CreatePaymentIntentResponse>> CreatePaymentIntent([FromBody] CreatePaymentIntentRequest request)
        {
            var order = await _db.Orders.FindAsync(request.OrderID);
            if (order == null)
            {
                return NotFound("Order not found");
            }

            if (!User.IsInRole("Admin"))
            {
                var userIdClaim = User.FindFirstValue(ClaimTypes.NameIdentifier);
                if (!int.TryParse(userIdClaim, out var currentUserId) || order.UserID != currentUserId)
                {
                    return Forbid();
                }
            }

            var validationError = await ValidateOrderForPayment(order);
            if (validationError != null) return BadRequest(validationError);

            var (amountInCents, calcError) = await CalculateOrderTotal(order.OrderID);
            if (calcError != null) return BadRequest(calcError);

            var currency = GetPaymentCurrency();
            var existingPayment = await GetExistingStripePaymentAsync(order);
            if (existingPayment.Error != null) return BadRequest(existingPayment.Error);

            if (existingPayment.ActiveCheckoutSession != null)
                return BadRequest("An active checkout session is already in progress for this order.");

            if (existingPayment.ActivePaymentIntent != null)
            {
                var activeIntent = existingPayment.ActivePaymentIntent;
                if (activeIntent.Amount != amountInCents
                    || !string.Equals(activeIntent.Currency, currency, StringComparison.OrdinalIgnoreCase))
                {
                    return BadRequest("Active payment amount does not match the current order total.");
                }

                return Ok(new CreatePaymentIntentResponse
                {
                    ClientSecret = activeIntent.ClientSecret,
                    PaymentIntentId = activeIntent.Id
                });
            }

            var metadata = new Dictionary<string, string>
            {
                {"order_id", order.OrderID.ToString()},
                {"order_number", order.OrderNumber },
                {"user_id", order.UserID.ToString() }
            };
            if (!string.IsNullOrWhiteSpace(request.ReceiptEmail))
            {
                metadata["receipt_email"] = request.ReceiptEmail;
            }

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

            return Ok(new CreatePaymentIntentResponse
            {
                ClientSecret = intent.ClientSecret,
                PaymentIntentId = intent.Id
            });
        }

        [HttpGet("stripe-config")]
        [AllowAnonymous]
        [ProducesResponseType(typeof(StripeConfigResponse), StatusCodes.Status200OK)]
        public ActionResult<StripeConfigResponse> GetStripeConfig()
        {
            var publishableKey = _configuration["Stripe:PublishableKey"] ?? string.Empty;

            return Ok(new StripeConfigResponse
            {
                PublishableKey = publishableKey,
                Currency = GetPaymentCurrency(),
                CurrencyDisplay = _configuration["Stripe:CurrencyDisplay"]?.Trim() is { Length: > 0 } d ? d : "KM"
            });
        }

        [ProducesResponseType(typeof(CreateCheckoutSessionResponse), StatusCodes.Status200OK)]
        [ProducesResponseType(StatusCodes.Status404NotFound)]
        [HttpPost("create-checkout-session")]
        [Authorize(Roles = "Buyer, Admin")]
        public async Task<ActionResult<CreateCheckoutSessionResponse>> CreateCheckoutSession([FromBody] CreateCheckoutSessionRequest request)
        {
            var order = await _db.Orders.Include(o => o.OrderItems).FirstOrDefaultAsync(o => o.OrderID == request.OrderID);
            if (order == null)
            {
                return NotFound("Order not found");
            }

            if (!User.IsInRole("Admin"))
            {
                var userIdClaim = User.FindFirstValue(ClaimTypes.NameIdentifier);
                if (!int.TryParse(userIdClaim, out var currentUserId) || order.UserID != currentUserId)
                {
                    return Forbid();
                }
            }

            var validationError = await ValidateOrderForPayment(order);
            if (validationError != null) return BadRequest(validationError);

            var (amountInCents, calcError) = await CalculateOrderTotal(order.OrderID);
            if (calcError != null) return BadRequest(calcError);

            var (successUrl, cancelUrl, successPrefix) = ResolveCheckoutRedirectUrls(Request);

            var currency = GetPaymentCurrency();
            var existingPayment = await GetExistingStripePaymentAsync(order);
            if (existingPayment.Error != null) return BadRequest(existingPayment.Error);

            if (existingPayment.ActivePaymentIntent != null)
                return BadRequest("An active payment intent is already in progress for this order.");

            if (existingPayment.ActiveCheckoutSession != null)
            {
                var activeSession = existingPayment.ActiveCheckoutSession;
                if (activeSession.AmountTotal.HasValue && activeSession.AmountTotal.Value != amountInCents)
                    return BadRequest("Active checkout amount does not match the current order total.");

                return Ok(new CreateCheckoutSessionResponse
                {
                    Url = activeSession.Url ?? string.Empty,
                    SessionId = activeSession.Id,
                    SuccessRedirectUrl = successPrefix,
                    CancelRedirectUrl = cancelUrl
                });
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

            if (order.ShippingStatus == CSBWebshopSeminarski.Core.Entities.ShippingStatus.Pending)
            {
                order.ShippingStatus = CSBWebshopSeminarski.Core.Entities.ShippingStatus.Processing;
                order.LastStatusUpdate = DateTime.UtcNow;
                await _db.SaveChangesAsync();
            }

            return Ok(new CreateCheckoutSessionResponse
            {
                Url = session.Url ?? string.Empty,
                SessionId = session.Id,
                SuccessRedirectUrl = successPrefix,
                CancelRedirectUrl = cancelUrl
            });
        }

        [HttpPost("confirm-checkout-session")]
        [Authorize(Roles = "Buyer, Admin")]
        public async Task<ActionResult<object>> ConfirmCheckoutSession([FromBody] ConfirmCheckoutSessionRequest request)
        {
            if (string.IsNullOrWhiteSpace(request.SessionId))
            {
                return BadRequest("SessionId is required.");
            }

            var sessionService = new SessionService();
            Session session;
            try
            {
                session = await sessionService.GetAsync(request.SessionId, new SessionGetOptions
                {
                    Expand = new List<string> { "payment_intent" }
                });
            }
            catch (StripeException ex)
            {
                return BadRequest($"Stripe session lookup failed: {ex.Message}");
            }

            if (session == null)
            {
                return NotFound("Session not found.");
            }

            var paymentIntentId = session.PaymentIntentId;
            if (string.IsNullOrWhiteSpace(paymentIntentId) && session.PaymentIntent is PaymentIntent piObj)
            {
                paymentIntentId = piObj.Id;
            }
            if (string.IsNullOrWhiteSpace(paymentIntentId))
            {
                return Ok(new { paid = false, reason = "payment_intent_missing" });
            }

            var paymentIntentService = new PaymentIntentService();
            PaymentIntent paymentIntent;
            try
            {
                paymentIntent = await paymentIntentService.GetAsync(paymentIntentId);
            }
            catch (StripeException ex)
            {
                return BadRequest($"Stripe payment intent lookup failed: {ex.Message}");
            }

            var metadata = paymentIntent.Metadata != null
                ? new Dictionary<string, string>(paymentIntent.Metadata)
                : new Dictionary<string, string>();
            if (!metadata.TryGetValue("order_id", out var metadataOrderId))
            {
                return Ok(new { paid = false, reason = "order_id_missing_in_metadata" });
            }

            if (!int.TryParse(metadataOrderId, out var orderIdFromMetadata))
            {
                return Ok(new { paid = false, reason = "invalid_order_id_metadata" });
            }

            var order = await _db.Orders.FirstOrDefaultAsync(o => o.OrderID == orderIdFromMetadata);
            if (order == null)
            {
                return NotFound("Order not found.");
            }

            if (!User.IsInRole("Admin"))
            {
                var userIdClaim = User.FindFirstValue(ClaimTypes.NameIdentifier);
                if (!int.TryParse(userIdClaim, out var currentUserId) || order.UserID != currentUserId)
                {
                    return Forbid();
                }
            }

            if (request.OrderId.HasValue && request.OrderId.Value != order.OrderID)
            {
                return BadRequest("Session does not belong to provided order.");
            }

            var isPaid = string.Equals(paymentIntent.Status, "succeeded", StringComparison.OrdinalIgnoreCase)
                         || string.Equals(session.PaymentStatus, "paid", StringComparison.OrdinalIgnoreCase);

            if (isPaid)
            {
                await _paymentsService.HandlePaymentSucceededAsync(paymentIntent.Id, metadata);
                return Ok(new { paid = true, orderId = order.OrderID, paymentIntentId = paymentIntent.Id });
            }

            return Ok(new { paid = false, orderId = order.OrderID, status = paymentIntent.Status });
        }

        [HttpPost("confirm-payment-intent")]
        [Authorize(Roles = "Buyer, Admin")]
        public async Task<ActionResult<object>> ConfirmPaymentIntent([FromBody] ConfirmPaymentIntentRequest request)
        {
            if (string.IsNullOrWhiteSpace(request.PaymentIntentId))
            {
                return BadRequest("PaymentIntentId is required.");
            }

            var paymentIntentService = new PaymentIntentService();
            PaymentIntent paymentIntent;
            try
            {
                paymentIntent = await paymentIntentService.GetAsync(request.PaymentIntentId);
            }
            catch (StripeException ex)
            {
                return BadRequest($"Stripe payment intent lookup failed: {ex.Message}");
            }

            if (paymentIntent == null)
            {
                return NotFound("Payment intent not found.");
            }

            var metadata = paymentIntent.Metadata != null
                ? new Dictionary<string, string>(paymentIntent.Metadata)
                : new Dictionary<string, string>();
            if (!metadata.TryGetValue("order_id", out var metadataOrderId))
            {
                return Ok(new { paid = false, reason = "order_id_missing_in_metadata" });
            }

            if (!int.TryParse(metadataOrderId, out var orderIdFromMetadata))
            {
                return Ok(new { paid = false, reason = "invalid_order_id_metadata" });
            }

            var order = await _db.Orders.FirstOrDefaultAsync(o => o.OrderID == orderIdFromMetadata);
            if (order == null)
            {
                return NotFound("Order not found.");
            }

            if (!User.IsInRole("Admin"))
            {
                var userIdClaim = User.FindFirstValue(ClaimTypes.NameIdentifier);
                if (!int.TryParse(userIdClaim, out var currentUserId) || order.UserID != currentUserId)
                {
                    return Forbid();
                }
            }

            if (request.OrderId.HasValue && request.OrderId.Value != order.OrderID)
            {
                return BadRequest("Payment intent does not belong to provided order.");
            }

            var isPaid = string.Equals(paymentIntent.Status, "succeeded", StringComparison.OrdinalIgnoreCase);

            if (isPaid)
            {
                await _paymentsService.HandlePaymentSucceededAsync(paymentIntent.Id, metadata);
                return Ok(new { paid = true, orderId = order.OrderID, paymentIntentId = paymentIntent.Id });
            }

            return Ok(new { paid = false, orderId = order.OrderID, status = paymentIntent.Status });
        }
    }
}
