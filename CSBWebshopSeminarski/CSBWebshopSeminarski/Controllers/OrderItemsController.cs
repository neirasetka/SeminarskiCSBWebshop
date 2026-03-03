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
        public OrderItemsController(ICRUDService<OrderItem, OrderItemSearchRequest, OrderItemUpsertRequest, OrderItemUpsertRequest> _service) : base(_service)
        {
        }

        [HttpPost]
        [Authorize(Roles = "Buyer, Admin")]
        public async Task<OrderItem> Insert([FromBody] OrderItemUpsertRequest request)
        {
            if (request == null)
                throw new UserException("Zahtjev za dodavanje stavke nije valjan.");
            try
            {
                return await base.Insert(request);
            }
            catch (DbUpdateException ex)
            {
                var inner = ex.InnerException?.Message ?? ex.Message;
                if (inner.Contains("FK_") || inner.Contains("foreign key") || inner.Contains("REFERENCE"))
                    throw new UserException("Greška pri dodavanju u korpu: narudžba, torba ili kaiš nije pronađen. Osvježite stranicu i pokušajte ponovno.");
                throw new UserException($"Greška pri dodavanju u korpu: {inner}");
            }
            catch (ArgumentException ex)
            {
                throw new UserException(ex.Message);
            }
        }
    }
}
