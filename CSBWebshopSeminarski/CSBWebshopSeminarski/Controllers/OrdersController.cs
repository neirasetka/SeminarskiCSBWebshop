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

        /// <summary>Pregled svih narudžbi (samo admin).</summary>
        [HttpGet]
        [Authorize(Roles = "Admin")]
        public override async Task<List<Order>> Get([FromQuery] OrderSearchRequest search)
        {
            return await _service.Get(search);
        }

        /// <summary>Puna narudžba sa stavkama; admin ili vlasnik narudžbe.</summary>
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
            return await _service.Insert(request);
        }

        [HttpGet("GetByOrderNumber")]
        [Authorize(Roles = "Buyer, Admin")]
        public Order GetByOrderNumber([FromQuery] string name)
        {
            return _service.GetByOrderNumber(name);
        }

        [HttpGet("Active")]
        [Authorize]
        public async Task<ActionResult<Order?>> GetActive([FromQuery] int userId)
        {
            var order = await _service.GetActiveCartByUser(userId);
            if (order == null)
            {
                return NoContent();
            }
            return Ok(order);
        }

        [HttpGet("ByUser")]
        [Authorize(Roles = "Buyer, Admin")]
        public async Task<ActionResult<List<Order>>> GetByUser([FromQuery] int userId)
        {
            if (!User.IsInRole("Admin"))
            {
                var userIdClaim = User.FindFirstValue(ClaimTypes.NameIdentifier);
                if (!int.TryParse(userIdClaim, out var currentUserId) || currentUserId != userId)
                {
                    return Forbid();
                }
            }
            var result = await _service.GetOrdersForUserAsync(userId);
            return Ok(result);
        }

        public class UpdatePaymentStatusRequest
        {
            public PaymentStatus Status { get; set; }

            /// <summary>Optional: email for payment confirmation (same as entered during checkout).</summary>
            public string? ReceiptEmail { get; set; }
        }

        [HttpDelete("Active")]
        [Authorize(Roles = "Buyer")]
        public async Task<ActionResult> CancelActiveCart([FromQuery] int userId)
        {
            var userIdClaim = User.FindFirstValue(ClaimTypes.NameIdentifier);
            if (!int.TryParse(userIdClaim, out var currentUserId) || currentUserId != userId)
            {
                return Forbid();
            }
            var ok = await _service.CancelActiveCartAsync(userId);
            if (!ok) return NoContent();
            return NoContent();
        }

        [HttpPatch("{orderId:int}/payment-status")]
        [Authorize(Roles = "Buyer, Admin")]
        public async Task<ActionResult> UpdatePaymentStatus(int orderId, [FromBody] UpdatePaymentStatusRequest request)
        {
            if (!User.IsInRole("Admin"))
            {
                var order = await _service.GetById(orderId);
                var userIdClaim = User.FindFirstValue(ClaimTypes.NameIdentifier);
                if (!int.TryParse(userIdClaim, out var currentUserId) || order.UserID != currentUserId)
                {
                    return Forbid();
                }
            }
            var ok = await _service.SetPaymentStatusAsync(orderId, request.Status, request.ReceiptEmail);
            if (!ok) return NotFound();
            return NoContent();
        }
    }
}
