using CBSWebshopSeminarski.Model.Models;
using CBSWebshopSeminarski.Model.Requests;
using CBSWebshopSeminarski.Services.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace CSBWebshopSeminarski.Controllers
{
    public class BeltTypesController : BaseCRUDController<BeltType, BeltTypeSearchRequest, BeltTypeUpsertRequest, BeltTypeUpsertRequest>
    {
        public BeltTypesController(ICRUDService<BeltType, BeltTypeSearchRequest, BeltTypeUpsertRequest, BeltTypeUpsertRequest> service) : base(service)
        {
        }

        [HttpGet]
        [AllowAnonymous]
        public override async Task<List<BeltType>> Get([FromQuery] BeltTypeSearchRequest search)
        {
            return await base.Get(search ?? new BeltTypeSearchRequest());
        }
    }
}
