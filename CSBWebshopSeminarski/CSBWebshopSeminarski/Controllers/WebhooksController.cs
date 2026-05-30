using CBSWebshopSeminarski.Model.Requests;
using CBSWebshopSeminarski.Services.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Security.Cryptography;
using System.Text;

namespace CSBWebshopSeminarski.Controllers
{
    [Route("api/webhooks/carriers/{carrierCode}")]
    [ApiController]
    public class WebhooksController : ControllerBase
    {
        private readonly IShipmentTrackingService _trackingService;
        private readonly IConfiguration _configuration;

        public WebhooksController(IShipmentTrackingService trackingService, IConfiguration configuration)
        {
            _trackingService = trackingService;
            _configuration = configuration;
        }

        [HttpPost("tracking")]
        [AllowAnonymous]
        public async Task<IActionResult> Tracking(string carrierCode, [FromBody] CarrierWebhookPayload payload)
        {
            var env = _configuration["ASPNETCORE_ENVIRONMENT"] ?? "Production";
            if (!string.Equals(env, "Development", StringComparison.OrdinalIgnoreCase))
            {
                var secret = _configuration["Webhooks:CarrierSecret"];
                if (string.IsNullOrWhiteSpace(secret))
                    return StatusCode(503, "Webhook secret not configured.");

                if (!Request.Headers.TryGetValue("X-Webhook-Signature", out var signatureHeader)
                    || string.IsNullOrWhiteSpace(signatureHeader))
                {
                    return Unauthorized("Missing webhook signature.");
                }

                Request.Body.Position = 0;
                using var reader = new StreamReader(Request.Body, leaveOpen: true);
                var body = await reader.ReadToEndAsync();

                using var hmac = new HMACSHA256(Encoding.UTF8.GetBytes(secret));
                var hash = hmac.ComputeHash(Encoding.UTF8.GetBytes(body));
                var expected = Convert.ToHexString(hash).ToLowerInvariant();

                if (!string.Equals(expected, signatureHeader.ToString().Trim(), StringComparison.OrdinalIgnoreCase))
                {
                    return Unauthorized("Invalid webhook signature.");
                }
            }

            await _trackingService.HandleCarrierWebhookAsync(carrierCode, payload);
            return Ok();
        }
    }
}
