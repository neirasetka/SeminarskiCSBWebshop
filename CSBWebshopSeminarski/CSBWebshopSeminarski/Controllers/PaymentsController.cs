using CBSWebshopSeminarski.Model.Requests;
using CBSWebshopSeminarski.Services.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Security.Claims;

namespace CSBWebshopSeminarski.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class PaymentsController : ControllerBase
    {
        private readonly IPaymentsService _paymentsService;

        public PaymentsController(IPaymentsService paymentsService)
        {
            _paymentsService = paymentsService;
        }

        [ProducesResponseType(typeof(CreatePaymentIntentResponse), StatusCodes.Status200OK)]
        [ProducesResponseType(StatusCodes.Status404NotFound)]
        [HttpPost("create-payment-intent")]
        [Authorize(Roles = "Buyer, Admin")]
        public async Task<ActionResult<CreatePaymentIntentResponse>> CreatePaymentIntent([FromBody] CreatePaymentIntentRequest request)
        {
            try
            {
                var (currentUserId, isAdmin) = GetCallerContext();
                var result = await _paymentsService.CreatePaymentIntentAsync(request, currentUserId, isAdmin);
                return Ok(result);
            }
            catch (KeyNotFoundException ex)
            {
                return NotFound(ex.Message);
            }
            catch (UnauthorizedAccessException)
            {
                return Forbid();
            }
            catch (InvalidOperationException ex)
            {
                return BadRequest(ex.Message);
            }
        }

        [HttpGet("stripe-config")]
        [AllowAnonymous]
        [ProducesResponseType(typeof(StripeConfigResponse), StatusCodes.Status200OK)]
        public ActionResult<StripeConfigResponse> GetStripeConfig()
        {
            return Ok(_paymentsService.GetStripeConfig());
        }

        [ProducesResponseType(typeof(CreateCheckoutSessionResponse), StatusCodes.Status200OK)]
        [ProducesResponseType(StatusCodes.Status404NotFound)]
        [HttpPost("create-checkout-session")]
        [Authorize(Roles = "Buyer, Admin")]
        public async Task<ActionResult<CreateCheckoutSessionResponse>> CreateCheckoutSession([FromBody] CreateCheckoutSessionRequest request)
        {
            try
            {
                var (currentUserId, isAdmin) = GetCallerContext();
                var redirectContext = new CheckoutRedirectContext
                {
                    RequestScheme = Request.Scheme,
                    RequestHost = Request.Host.Value
                };
                var result = await _paymentsService.CreateCheckoutSessionAsync(request, currentUserId, isAdmin, redirectContext);
                return Ok(result);
            }
            catch (KeyNotFoundException ex)
            {
                return NotFound(ex.Message);
            }
            catch (UnauthorizedAccessException)
            {
                return Forbid();
            }
            catch (InvalidOperationException ex)
            {
                return BadRequest(ex.Message);
            }
        }

        [HttpPost("confirm-checkout-session")]
        [Authorize(Roles = "Buyer, Admin")]
        public async Task<ActionResult<object>> ConfirmCheckoutSession([FromBody] ConfirmCheckoutSessionRequest request)
        {
            if (string.IsNullOrWhiteSpace(request.SessionId))
            {
                return BadRequest("SessionId is required.");
            }

            try
            {
                var (currentUserId, isAdmin) = GetCallerContext();
                var result = await _paymentsService.ConfirmCheckoutSessionAsync(
                    request.SessionId,
                    request.OrderId,
                    currentUserId,
                    isAdmin);

                return Ok(MapConfirmResult(result));
            }
            catch (KeyNotFoundException ex)
            {
                return NotFound(ex.Message);
            }
            catch (UnauthorizedAccessException)
            {
                return Forbid();
            }
            catch (InvalidOperationException ex)
            {
                return BadRequest(ex.Message);
            }
        }

        [HttpPost("confirm-payment-intent")]
        [Authorize(Roles = "Buyer, Admin")]
        public async Task<ActionResult<object>> ConfirmPaymentIntent([FromBody] ConfirmPaymentIntentRequest request)
        {
            if (string.IsNullOrWhiteSpace(request.PaymentIntentId))
            {
                return BadRequest("PaymentIntentId is required.");
            }

            try
            {
                var (currentUserId, isAdmin) = GetCallerContext();
                var result = await _paymentsService.ConfirmPaymentIntentAsync(
                    request.PaymentIntentId,
                    request.OrderId,
                    currentUserId,
                    isAdmin);

                return Ok(MapConfirmResult(result));
            }
            catch (KeyNotFoundException ex)
            {
                return NotFound(ex.Message);
            }
            catch (UnauthorizedAccessException)
            {
                return Forbid();
            }
            catch (InvalidOperationException ex)
            {
                return BadRequest(ex.Message);
            }
        }

        private (int? currentUserId, bool isAdmin) GetCallerContext()
        {
            var isAdmin = User.IsInRole("Admin");
            int? currentUserId = null;
            if (!isAdmin)
            {
                var userIdClaim = User.FindFirstValue(ClaimTypes.NameIdentifier);
                if (int.TryParse(userIdClaim, out var parsedUserId))
                {
                    currentUserId = parsedUserId;
                }
            }
            return (currentUserId, isAdmin);
        }

        private static object MapConfirmResult(PaymentConfirmResult result)
        {
            if (result.Paid)
            {
                return new { paid = true, orderId = result.OrderId, paymentIntentId = result.PaymentIntentId };
            }

            if (!string.IsNullOrEmpty(result.Reason))
            {
                return new { paid = false, reason = result.Reason };
            }

            return new { paid = false, orderId = result.OrderId, status = result.Status };
        }
    }
}
