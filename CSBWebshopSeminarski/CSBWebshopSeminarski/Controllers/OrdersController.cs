using CBSWebshopSeminarski.Model.Models;
using CBSWebshopSeminarski.Model.Requests;
using CBSWebshopSeminarski.Services.Interfaces;
using CSBWebshopSeminarski.Core.Entities;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Security.Claims;

namespace CSBWebshopSeminarski.Controllers
{
    public class OrdersController : BaseCRUDController<Order, OrderSearchRequest, OrderUpsertRequest, OrderUpsertRequest>
    {
        private readonly IOrderService _service;

        public OrdersController(IOrderService service) : base(service)
        {
            _service = service;
        }

        [HttpGet]
        [Authorize(Roles = "Admin")]
        public override async Task<List<Order>> Get([FromQuery] OrderSearchRequest search)
        {
            return await _service.Get(search);
        }

        [HttpGet("{ID:int}")]
        [Authorize]
        public override async Task<Order> GetById(int ID)
        {
            var order = await _service.GetFullOrderByIdAsync(ID);
            if (order == null)
            {
                throw new KeyNotFoundException("Narudžba nije pronađena.");
            }
            if (!User.IsInRole("Admin"))
            {
                var userIdClaim = User.FindFirstValue(ClaimTypes.NameIdentifier);
                if (!int.TryParse(userIdClaim, out var currentUserId) || currentUserId != order.UserID)
                {
                    throw new UnauthorizedAccessException();
                }
            }
            return order;
        }

        [HttpPost("Create")]
        [Authorize(Roles = "Buyer, Admin")]
        public async Task<Order> Create([FromBody] OrderUpsertRequest request)
        {
            var userIdClaim = User.FindFirstValue(ClaimTypes.NameIdentifier);
            if (!int.TryParse(userIdClaim, out var currentUserId))
            {
                throw new UnauthorizedAccessException();
            }
            request.UserID = currentUserId;
            request.Price = 0;
            return await _service.Insert(request);
        }

        [HttpGet("GetByOrderNumber")]
        [Authorize(Roles = "Buyer, Admin")]
        public async Task<ActionResult<Order>> GetByOrderNumber([FromQuery] string name)
        {
            var order = _service.GetByOrderNumber(name);
            if (!User.IsInRole("Admin"))
            {
                var userIdClaim = User.FindFirstValue(ClaimTypes.NameIdentifier);
                if (!int.TryParse(userIdClaim, out var currentUserId) || currentUserId != order.UserID)
                {
                    return Forbid();
                }
            }
            return Ok(order);
        }

        [HttpGet("Active")]
        [Authorize]
        public async Task<ActionResult<Order?>> GetActive()
        {
            var userIdClaim = User.FindFirstValue(ClaimTypes.NameIdentifier);
            if (!int.TryParse(userIdClaim, out var currentUserId))
            {
                return Unauthorized();
            }
            var order = await _service.GetActiveCartByUser(currentUserId);
            if (order == null)
            {
                return NoContent();
            }
            return Ok(order);
        }

        [HttpGet("My")]
        [Authorize(Roles = "Buyer, Admin")]
        public async Task<ActionResult<List<Order>>> GetMyOrders()
        {
            var userIdClaim = User.FindFirstValue(ClaimTypes.NameIdentifier);
            if (!int.TryParse(userIdClaim, out var currentUserId))
            {
                return Unauthorized();
            }
            var result = await _service.GetOrdersForUserAsync(currentUserId);
            return Ok(result);
        }

        [HttpGet("ByUser")]
        [Authorize(Roles = "Admin")]
        public async Task<ActionResult<List<Order>>> GetByUser([FromQuery] int userId)
        {
            var result = await _service.GetOrdersForUserAsync(userId);
            return Ok(result);
        }

        public class UpdatePaymentStatusRequest
        {
            public PaymentStatus Status { get; set; }
            public string? ReceiptEmail { get; set; }
        }

        public class CancelOrderRequest
        {
            public string? Reason { get; set; }
        }

        [HttpDelete("{ID:int}")]
        [Authorize(Roles = "Admin")]
        public override async Task<bool> Delete(int ID)
        {
            var userIdClaim = User.FindFirstValue(ClaimTypes.NameIdentifier);
            if (!int.TryParse(userIdClaim, out var adminUserId))
                throw new UnauthorizedAccessException();

            var cancelled = await _service.CancelOrderAsync(ID, adminUserId, "Cancelled by administrator");
            if (!cancelled)
                throw new KeyNotFoundException("Narudžba nije pronađena ili je već otkazana.");
            return true;
        }

        [HttpPatch("{ID:int}/cancel")]
        [Authorize(Roles = "Admin")]
        public async Task<ActionResult> CancelOrder(int ID, [FromBody] CancelOrderRequest? request)
        {
            var userIdClaim = User.FindFirstValue(ClaimTypes.NameIdentifier);
            if (!int.TryParse(userIdClaim, out var adminUserId))
                return Unauthorized();

            var reason = string.IsNullOrWhiteSpace(request?.Reason)
                ? "Cancelled by administrator"
                : request!.Reason!.Trim();

            var cancelled = await _service.CancelOrderAsync(ID, adminUserId, reason);
            if (!cancelled)
                return NotFound();

            return NoContent();
        }

        [HttpDelete("Active")]
        [Authorize(Roles = "Buyer")]
        public async Task<ActionResult> CancelActiveCart([FromQuery] string? reason = null)
        {
            var userIdClaim = User.FindFirstValue(ClaimTypes.NameIdentifier);
            if (!int.TryParse(userIdClaim, out var currentUserId))
            {
                return Unauthorized();
            }
            var cancelled = await _service.CancelActiveCartAsync(currentUserId, reason);
            if (!cancelled)
                return NotFound();
            return NoContent();
        }

        [HttpPatch("{orderId:int}/payment-status")]
        [Authorize(Roles = "Admin")]
        public async Task<ActionResult> UpdatePaymentStatus(int orderId, [FromBody] UpdatePaymentStatusRequest request)
        {
            var ok = await _service.SetPaymentStatusAsync(orderId, request.Status, request.ReceiptEmail);
            if (!ok) return NotFound();
            return NoContent();
        }
    }
}
