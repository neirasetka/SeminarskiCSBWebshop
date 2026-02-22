using CBSWebshopSeminarski.Model.Models;
using CBSWebshopSeminarski.Model.Requests;
using CBSWebshopSeminarski.Services.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace CSBWebshopSeminarski.Controllers
{
    public class BagTypesController : BaseCRUDController<BagType, BagTypeSearchRequest, BagTypeUpsertRequest, BagTypeUpsertRequest>
    {
        public BagTypesController(ICRUDService<BagType, BagTypeSearchRequest, BagTypeUpsertRequest, BagTypeUpsertRequest> service) : base(service)
        {
        }

        [HttpGet]
        [AllowAnonymous]
        public override async Task<List<BagType>> Get([FromQuery] BagTypeSearchRequest search)
        {
            return await base.Get(search ?? new BagTypeSearchRequest());
        }
    }
}
