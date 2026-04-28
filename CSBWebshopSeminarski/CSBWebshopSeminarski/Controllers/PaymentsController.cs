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

        public PaymentsController(CocoSunBagsWebshopDbContext db, IPaymentsService paymentsService)
        {
            _db = db;
            _paymentsService = paymentsService;
        }

        public class ConfirmCheckoutSessionRequest
        {
            public string SessionId { get; set; } = string.Empty;
            public int? OrderId { get; set; }
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

        /// <summary>
        /// Create Stripe PaymentIntent for a given Order.
        /// </summary>
        /// <remarks>
        /// Returns a client_secret used by the client to complete the payment.
        /// </remarks>
        /// <response code="200">Returns client secret and intent id</response>
        /// <response code="404">Order not found</response>
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

            var amount = request.AmountInCents > 0 ? request.AmountInCents : (long)(order.Price * 100);
            var currency = string.IsNullOrWhiteSpace(request.Currency) ? "eur" : request.Currency!;

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
                Amount = amount,
                Currency = currency,
                Metadata = metadata,
                ReceiptEmail = request.ReceiptEmail,
                AutomaticPaymentMethods = new PaymentIntentAutomaticPaymentMethodsOptions
                {
                    Enabled = true
                }
            };

            var intent = await paymentIntentService.CreateAsync(createOptions);

            return Ok(new CreatePaymentIntentResponse
            {
                ClientSecret = intent.ClientSecret,
                PaymentIntentId = intent.Id
            });
        }

        /// <summary>
        /// Create Stripe Checkout Session for Hosted Checkout (desktop/web browser flow).
        /// </summary>
        /// <remarks>
        /// Returns a URL to open in the browser. Used when Payment Sheet is not available (e.g. Windows desktop).
        /// </remarks>
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

            var amount = (long)(order.Price * 100);
            if (amount < 50)
            {
                amount = 50;
            }

            var baseUrl = $"{Request.Scheme}://{Request.Host.Value}";
            var successUrl = string.IsNullOrWhiteSpace(request.SuccessUrl)
                ? $"{baseUrl}/checkout-success?session_id={{CHECKOUT_SESSION_ID}}"
                : request.SuccessUrl;
            var cancelUrl = string.IsNullOrWhiteSpace(request.CancelUrl)
                ? $"{baseUrl}/checkout-cancel"
                : request.CancelUrl;

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
                            Currency = "eur",
                            UnitAmount = amount,
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

            var session = await sessionService.CreateAsync(createOptions);

            // Kada checkout sesija krene, narudžba više nije aktivna korpa.
            // Ovo sprečava ponovno korištenje iste pending narudžbe pri narednoj kupovini.
            if (order.ShippingStatus == CSBWebshopSeminarski.Core.Entities.ShippingStatus.Pending)
            {
                order.ShippingStatus = CSBWebshopSeminarski.Core.Entities.ShippingStatus.Processing;
                order.LastStatusUpdate = DateTime.UtcNow;
                await _db.SaveChangesAsync();
            }

            return Ok(new CreateCheckoutSessionResponse
            {
                Url = session.Url ?? string.Empty,
                SessionId = session.Id
            });
        }

        /// <summary>
        /// Fallback confirmation path when webhook delivery is delayed/unavailable.
        /// Checks Stripe Checkout Session and updates order payment status if paid.
        /// </summary>
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
    }
}
