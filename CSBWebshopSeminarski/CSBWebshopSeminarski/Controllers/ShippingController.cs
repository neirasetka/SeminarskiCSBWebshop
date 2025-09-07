using CBSWebshopSeminarski.Model.Models;
using CBSWebshopSeminarski.Model.Requests;
using CBSWebshopSeminarski.Services.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace CSBWebshopSeminarski.Controllers
{
    [Route("api/orders/{orderId:int}/shipping")]
    [ApiController]
    public class ShippingController : ControllerBase
    {
        private readonly IShipmentTrackingService _trackingService;

        public ShippingController(IShipmentTrackingService trackingService)
        {
            _trackingService = trackingService;
        }

        [HttpPost]
        [Authorize(Roles = "Admin")]
        public async Task<ActionResult<ShippingInfo>> SetTrackingInfo(int orderId, [FromBody] SetShippingInfoRequest request)
        {
            var result = await _trackingService.SetTrackingInfoAsync(orderId, request);
            return Ok(result);
        }

        [HttpGet]
        [Authorize]
        public async Task<ActionResult<ShippingInfo>> GetShippingInfo(int orderId)
        {
            var result = await _trackingService.GetShippingInfoAsync(orderId);
            return Ok(result);
        }

        [HttpPatch("status")]
        [Authorize(Roles = "Admin")]
        public async Task<ActionResult<ShippingInfo>> UpdateStatus(int orderId, [FromBody] UpdateShippingStatusRequest request)
        {
            var result = await _trackingService.UpdateStatusAsync(orderId, request);
            return Ok(result);
        }
    }
}
