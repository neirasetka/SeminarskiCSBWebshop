using CBSWebshopSeminarski.Model.Models;
using CBSWebshopSeminarski.Model.Requests;
using CBSWebshopSeminarski.Services.Exceptions;
using CBSWebshopSeminarski.Services.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System.Security.Claims;

namespace CSBWebshopSeminarski.Controllers
{
    public class OrderItemsController : BaseCRUDController<OrderItem, OrderItemSearchRequest, OrderItemUpsertRequest, OrderItemUpsertRequest>
    {
        private readonly ILogger<OrderItemsController> _logger;
        private readonly IOrderService _orderService;

        public OrderItemsController(
            ICRUDService<OrderItem, OrderItemSearchRequest, OrderItemUpsertRequest, OrderItemUpsertRequest> service,
            IOrderService orderService,
            ILogger<OrderItemsController> logger) : base(service)
        {
            _logger = logger;
            _orderService = orderService;
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

            try
            {
                return await base.Insert(upsert);
            }
            catch (DbUpdateException ex)
            {
                var inner = ex.InnerException?.Message ?? ex.Message;
                _logger.LogWarning(ex, "DbUpdateException adding item to cart. OrderID={OrderId} BagID={BagId} BeltID={BeltId}", upsert.OrderID, upsert.BagID, upsert.BeltID);
                if (inner.Contains("FK_") || inner.Contains("foreign key") || inner.Contains("REFERENCE"))
                    throw new NotFoundException("Greška pri dodavanju u korpu: narudžba, torba ili kaiš nije pronađen. Osvježite stranicu i pokušajte ponovno.");
                if (inner.Contains("Cannot insert the value NULL into column", StringComparison.OrdinalIgnoreCase)
                    && (inner.Contains("BagID", StringComparison.OrdinalIgnoreCase) || inner.Contains("BeltID", StringComparison.OrdinalIgnoreCase)))
                    throw new ValidationException(
                        "Struktura baze ne dopušta stavku samo s torbom ili samo s kaišem. Ponovno pokrenite web API (pri pokretanju se ispravljaju stupci OrderItems.BagID/BeltID). Ako problem ostane, ručno postavite te stupce na NULL u SQL Serveru.");
                throw;
            }
        }
    }
}
