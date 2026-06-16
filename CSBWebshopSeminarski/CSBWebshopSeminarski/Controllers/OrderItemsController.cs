using CBSWebshopSeminarski.Model.Models;
using CBSWebshopSeminarski.Model.Requests;
using CBSWebshopSeminarski.Services.Exceptions;
using CBSWebshopSeminarski.Services.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Security.Claims;

namespace CSBWebshopSeminarski.Controllers
{
    public class OrderItemsController : BaseCRUDController<OrderItem, OrderItemSearchRequest, OrderItemUpsertRequest, OrderItemUpsertRequest>
    {
        private readonly IOrderService _orderService;

        public OrderItemsController(
            ICRUDService<OrderItem, OrderItemSearchRequest, OrderItemUpsertRequest, OrderItemUpsertRequest> service,
            IOrderService orderService) : base(service)
        {
            _orderService = orderService;
        }

        [HttpGet]
        [Authorize]
        public override async Task<PagedResult<OrderItem>> Get([FromQuery] OrderItemSearchRequest search)
        {
            if (!User.IsInRole("Admin"))
            {
                if (search?.OrderID is not int orderId || orderId <= 0)
                    throw new ForbiddenException("Access denied.");

                await EnsureOrderAccessAsync(orderId);
            }

            return await base.Get(search);
        }

        [HttpGet("{ID:int}")]
        [Authorize]
        public override async Task<OrderItem> GetById(int ID)
        {
            var item = await base.GetById(ID);
            if (!User.IsInRole("Admin"))
                await EnsureOrderAccessAsync(item.OrderID);

            return item;
        }

        private async Task EnsureOrderAccessAsync(int orderId)
        {
            var order = await _orderService.GetFullOrderByIdAsync(orderId);
            if (order == null)
                throw new NotFoundException($"Order with ID {orderId} not found.");

            var userIdClaim = User.FindFirstValue(ClaimTypes.NameIdentifier);
            if (!int.TryParse(userIdClaim, out var currentUserId) || currentUserId != order.UserID)
                throw new ForbiddenException("Access denied.");
        }

        /// <summary>
        /// Dodavanje stavke u korpu. Zaseban endpoint jer BaseCRUDController.Insert ima [Authorize(Roles = "Admin")]
        /// koji se zbraja s ovim atributom - zato Buyer ne bi prolazio na standardnom POST.
        /// </summary>
        [HttpPost("AddToCart")]
        [Authorize(Roles = "Buyer, Admin")]
        public async Task<OrderItem> AddToCart([FromBody] AddToCartRequest request)
        {
            if (request == null)
                throw new ValidationException("Zahtjev za dodavanje stavke nije valjan.");

            var upsert = new OrderItemUpsertRequest
            {
                BagID = request.BagID,
                BeltID = request.BeltID,
                OrderID = request.OrderID,
                Quantity = request.Quantity,
            };

            if (!User.IsInRole("Admin"))
            {
                var userIdClaim = User.FindFirstValue(ClaimTypes.NameIdentifier);
                if (!int.TryParse(userIdClaim, out var currentUserId))
                    throw new ForbiddenException("Access denied.");

                var order = await _orderService.GetFullOrderByIdAsync(request.OrderID);
                if (order == null)
                    throw new NotFoundException($"Order with ID {request.OrderID} not found.");
                if (order.UserID != currentUserId)
                    throw new ForbiddenException("Access denied.");
            }

            return await base.Insert(upsert);
        }
    }
}
