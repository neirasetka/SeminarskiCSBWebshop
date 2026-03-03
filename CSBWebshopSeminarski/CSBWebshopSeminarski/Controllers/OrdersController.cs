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
            var orders = await _service.Get(new OrderSearchRequest());
            var result = orders.Where(o => o.UserID == userId).OrderByDescending(o => o.Date).ToList();
            return Ok(result);
        }

        public class UpdatePaymentStatusRequest
        {
            public PaymentStatus Status { get; set; }
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
            var ok = await _service.SetPaymentStatusAsync(orderId, request.Status);
            if (!ok) return NotFound();
            return NoContent();
        }
    }
}
