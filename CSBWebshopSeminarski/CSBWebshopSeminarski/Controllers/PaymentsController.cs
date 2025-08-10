using CBSWebshopSeminarski.Model.Requests;
using CBSWebshopSeminarski.Services.Interfaces;
using CSBWebshopSeminarski.Core.Entities;
using CSBWebshopSeminarski.Database;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Stripe;
using Stripe.Checkout;

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