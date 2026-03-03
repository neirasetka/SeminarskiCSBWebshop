using CBSWebshopSeminarski.Model.Models;
using CBSWebshopSeminarski.Model.Requests;
using CBSWebshopSeminarski.Services.Interfaces;
using CSBWebshopSeminarski.Exceptions;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace CSBWebshopSeminarski.Controllers
{
    public class OrderItemsController : BaseCRUDController<OrderItem, OrderItemSearchRequest, OrderItemUpsertRequest, OrderItemUpsertRequest>
    {
        private readonly ILogger<OrderItemsController> _logger;

        public OrderItemsController(
            ICRUDService<OrderItem, OrderItemSearchRequest, OrderItemUpsertRequest, OrderItemUpsertRequest> service,
            ILogger<OrderItemsController> logger) : base(service)
        {
            _logger = logger;
        }

        [HttpPost]
        [Authorize(Roles = "Buyer, Admin")]
        public override async Task<OrderItem> Insert([FromBody] OrderItemUpsertRequest request)
        {
            if (request == null)
                throw new UserException("Zahtjev za dodavanje stavke nije valjan.");
            try
            {
                return await base.Insert(request);
            }
            catch (UserException)
            {
                throw;
            }
            catch (DbUpdateException ex)
            {
                var inner = ex.InnerException?.Message ?? ex.Message;
                _logger.LogWarning(ex, "DbUpdateException adding item to cart. OrderID={OrderId} BagID={BagId} BeltID={BeltId}", request.OrderID, request.BagID, request.BeltID);
                if (inner.Contains("FK_") || inner.Contains("foreign key") || inner.Contains("REFERENCE"))
                    throw new UserException("Greška pri dodavanju u korpu: narudžba, torba ili kaiš nije pronađen. Osvježite stranicu i pokušajte ponovno.");
                throw new UserException($"Greška pri dodavanju u korpu: {inner}");
            }
            catch (ArgumentException ex)
            {
                throw new UserException(ex.Message);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Unexpected error adding item to cart. OrderID={OrderId} BagID={BagId} BeltID={BeltId}", request.OrderID, request.BagID, request.BeltID);
                throw new UserException("Greška pri dodavanju u korpu. Osvježite stranicu i pokušajte ponovno.");
            }
        }
    }
}
