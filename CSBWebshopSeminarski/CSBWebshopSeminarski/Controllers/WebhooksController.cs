using CBSWebshopSeminarski.Model.Requests;
using CBSWebshopSeminarski.Services.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace CSBWebshopSeminarski.Controllers
{
    [Route("api/webhooks/carriers/{carrierCode}")]
    [ApiController]
    public class WebhooksController : ControllerBase
    {
        private readonly IShipmentTrackingService _trackingService;

        public WebhooksController(IShipmentTrackingService trackingService)
        {
            _trackingService = trackingService;
        }

        // Allow anonymous; validate via signature header if needed
        [HttpPost("tracking")]
        [AllowAnonymous]
        public async Task<IActionResult> Tracking(string carrierCode, [FromBody] CarrierWebhookPayload payload)
        {
            await _trackingService.HandleCarrierWebhookAsync(carrierCode, payload);
            return Ok();
        }
    }
}