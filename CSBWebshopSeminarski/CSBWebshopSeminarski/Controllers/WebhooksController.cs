using CBSWebshopSeminarski.Model.Requests;
using CBSWebshopSeminarski.Services;
using CBSWebshopSeminarski.Services.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace CSBWebshopSeminarski.Controllers
{
    /// <summary>
    /// Simulacija carrier webhooka za seminarski rad — dostupno samo u Development okruženju.
    /// </summary>
    [Route("api/webhooks/carriers/{carrierCode}")]
    [ApiController]
    public class WebhooksController : ControllerBase
    {
        private readonly IShipmentTrackingService _trackingService;
        private readonly IWebHostEnvironment _environment;

        public WebhooksController(
            IShipmentTrackingService trackingService,
            IWebHostEnvironment environment)
        {
            _trackingService = trackingService;
            _environment = environment;
        }

        [HttpPost("tracking")]
        [AllowAnonymous]
        public async Task<IActionResult> Tracking(string carrierCode, [FromBody] CarrierWebhookPayload payload)
        {
            if (!_environment.IsDevelopment())
                return NotFound();

            CarrierWebhookValidator.Validate(carrierCode, payload);

            await _trackingService.HandleCarrierWebhookAsync(carrierCode, payload);
            return Ok();
        }
    }
}
