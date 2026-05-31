using CBSWebshopSeminarski.Model.Models;
using CBSWebshopSeminarski.Model.Requests;
using CBSWebshopSeminarski.Services.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace CSBWebshopSeminarski.Controllers
{
    public class PurchasesController : BaseCRUDController<Purchase, PurchaseSearchRequest, PurchaseUpsertRequest, PurchaseUpsertRequest>
    {
        public PurchasesController(ICRUDService<Purchase, PurchaseSearchRequest, PurchaseUpsertRequest, PurchaseUpsertRequest> service) : base(service)
        {
        }

        [HttpGet]
        [Authorize(Roles = "Admin")]
        public override async Task<PagedResult<Purchase>> Get([FromQuery] PurchaseSearchRequest search)
        {
            return await base.Get(search);
        }

        [HttpGet("{ID:int}")]
        [Authorize(Roles = "Admin")]
        public override async Task<Purchase> GetById(int ID)
        {
            return await base.GetById(ID);
        }
    }
}
