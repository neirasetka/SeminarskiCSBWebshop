using CBSWebshopSeminarski.Model.Models;
using CBSWebshopSeminarski.Model.Requests;
using CBSWebshopSeminarski.Services.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace CSBWebshopSeminarski.Controllers
{
    [AllowAnonymous]
    public class BagTypesController : BaseCRUDController<BagType, BagTypeSearchRequest, BagTypeUpsertRequest, BagTypeUpsertRequest>
    {
        public BagTypesController(ICRUDService<BagType, BagTypeSearchRequest, BagTypeUpsertRequest, BagTypeUpsertRequest> service) : base(service)
        {
        }

        [HttpGet]
        [AllowAnonymous]
        public override async Task<PagedResult<BagType>> Get([FromQuery] BagTypeSearchRequest search)
        {
            return await base.Get(search ?? new BagTypeSearchRequest());
        }

        [HttpGet("{ID:int}")]
        [AllowAnonymous]
        public override async Task<BagType> GetById(int ID)
        {
            return await base.GetById(ID);
        }
    }
}
