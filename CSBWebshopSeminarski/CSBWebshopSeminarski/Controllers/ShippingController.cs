using CBSWebshopSeminarski.Model.Models;
using CBSWebshopSeminarski.Model.Requests;
using CBSWebshopSeminarski.Services.Exceptions;
using CBSWebshopSeminarski.Services.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Security.Claims;

namespace CSBWebshopSeminarski.Controllers
{
    [Route("api/orders/{orderId:int}/shipping")]
    [ApiController]
    public class ShippingController : ControllerBase
    {
        private readonly IShipmentTrackingService _trackingService;
        private readonly IOrderService _orderService;

        public ShippingController(
            IShipmentTrackingService trackingService,
            IOrderService orderService)
        {
            _trackingService = trackingService;
            _orderService = orderService;
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
            if (!User.IsInRole("Admin"))
            {
                var userIdClaim = User.FindFirstValue(ClaimTypes.NameIdentifier);
                if (!int.TryParse(userIdClaim, out var currentUserId))
                    throw new ForbiddenException("Access denied.");

                var order = await _orderService.GetFullOrderByIdAsync(orderId);
                if (order == null)
                    throw new NotFoundException("Narudžba nije pronađena.");
                if (order.UserID != currentUserId)
                    throw new ForbiddenException("Access denied.");
            }

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
