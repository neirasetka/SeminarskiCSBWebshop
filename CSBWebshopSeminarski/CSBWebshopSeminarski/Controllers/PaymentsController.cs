using CBSWebshopSeminarski.Model.Requests;
using CSBWebshopSeminarski.Database;
using Microsoft.AspNetCore.Authorization;
using Microsoft.EntityFrameworkCore;
using Microsoft.AspNetCore.Mvc;
using Stripe;
using System.Security.Claims;

namespace CSBWebshopSeminarski.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class PaymentsController : ControllerBase
    {
        private readonly CocoSunBagsWebshopDbContext _db;

        public PaymentsController(CocoSunBagsWebshopDbContext db)
        {
            _db = db;
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

            var paymentIntentService = new PaymentIntentService();
            var createOptions = new PaymentIntentCreateOptions
            {
                Amount = amount,
                Currency = currency,
                Metadata = new Dictionary<string, string>
                {
                    {"order_id", order.OrderID.ToString()},
                    {"order_number", order.OrderNumber },
                    {"user_id", order.UserID.ToString() }
                },
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
                    Metadata = new Dictionary<string, string>
                    {
                        { "order_id", order.OrderID.ToString() },
                        { "order_number", order.OrderNumber },
                        { "user_id", order.UserID.ToString() }
                    }
                }
            };

            if (!string.IsNullOrWhiteSpace(request.ReceiptEmail))
            {
                createOptions.CustomerEmail = request.ReceiptEmail;
            }

            var session = await sessionService.CreateAsync(createOptions);

            return Ok(new CreateCheckoutSessionResponse
            {
                Url = session.Url ?? string.Empty,
                SessionId = session.Id
            });
        }
    }
}
