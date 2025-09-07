using CBSWebshopSeminarski.Model.Requests;
using CSBWebshopSeminarski.Database;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Stripe;

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
    }
}
