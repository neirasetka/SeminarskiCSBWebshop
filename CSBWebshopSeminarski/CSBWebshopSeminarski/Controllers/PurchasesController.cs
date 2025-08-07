using CBSWebshopSeminarski.Model.Models;
using CBSWebshopSeminarski.Model.Requests;
using CBSWebshopSeminarski.Services.Interfaces;
using CSBWebshopSeminarski.Core.Entities;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;

namespace CSBWebshopSeminarski.Controllers
{
    public class PurchasesController : BaseCRUDController<Purchase, PurchaseSearchRequest, PurchaseUpsertRequest, PurchaseUpsertRequest>
    {
        public PurchasesController(ICRUDService<Purchase, PurchaseSearchRequest, PurchaseUpsertRequest, PurchaseUpsertRequest> _service) : base(_service)
        {
        }
    }
}
