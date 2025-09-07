using CBSWebshopSeminarski.Model.Models;
using CBSWebshopSeminarski.Model.Requests;
using CBSWebshopSeminarski.Services.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace CSBWebshopSeminarski.Controllers
{
    public class OrderItemsController : BaseCRUDController<OrderItem, OrderItemSearchRequest, OrderItemUpsertRequest, OrderItemUpsertRequest>
    {
        public OrderItemsController(ICRUDService<OrderItem, OrderItemSearchRequest, OrderItemUpsertRequest, OrderItemUpsertRequest> _service) : base(_service)
        {
        }

        [HttpPost]
        [Authorize(Roles = "Buyer, Admin")]
        public async Task<OrderItem> Insert(OrderItemUpsertRequest request)
        {
            return await base.Insert(request);
        }
    }
}
