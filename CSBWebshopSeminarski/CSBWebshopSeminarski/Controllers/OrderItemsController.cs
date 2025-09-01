using CBSWebshopSeminarski.Model.Models;
using CBSWebshopSeminarski.Model.Requests;
using CBSWebshopSeminarski.Services.Interfaces;
using CSBWebshopSeminarski.Core.Entities;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Authorization;

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
