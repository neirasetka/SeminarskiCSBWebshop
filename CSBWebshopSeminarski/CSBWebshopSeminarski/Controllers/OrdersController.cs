using CBSWebshopSeminarski.Model.Models;
using CBSWebshopSeminarski.Model.Requests;
using CBSWebshopSeminarski.Services.Interfaces;
using CSBWebshopSeminarski.Core.Entities;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Authorization;

namespace CSBWebshopSeminarski.Controllers
{
    public class OrdersController : BaseCRUDController<Order, OrderSearchRequest, OrderUpsertRequest, OrderUpsertRequest>
    {
        private readonly IOrderService _service;

        public OrdersController(IOrderService service) : base(service)
        {
            _service = service;
        }

        [HttpGet("GetByOrderNumber")]
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
    }
}
