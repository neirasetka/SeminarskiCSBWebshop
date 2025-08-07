using CBSWebshopSeminarski.Model.Models;
using CBSWebshopSeminarski.Model.Requests;
using CBSWebshopSeminarski.Services.Interfaces;
using CSBWebshopSeminarski.Core.Entities;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;

namespace CSBWebshopSeminarski.Controllers
{
    public class BagTypesController : BaseCRUDController<BagType, BagTypeSearchRequest, BagTypeUpsertRequest, BagTypeUpsertRequest>
    {
        public BagTypesController(ICRUDService<BagType, BagTypeSearchRequest, BagTypeUpsertRequest, BagTypeUpsertRequest> service) : base(service)
        {
        }
    }
}
