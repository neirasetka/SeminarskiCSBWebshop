using CBSWebshopSeminarski.Model.Models;
using CBSWebshopSeminarski.Model.Requests;
using CBSWebshopSeminarski.Services.Interfaces;

namespace CSBWebshopSeminarski.Controllers
{
    public class PurchasesController : BaseCRUDController<Purchase, PurchaseSearchRequest, PurchaseUpsertRequest, PurchaseUpsertRequest>
    {
        public PurchasesController(ICRUDService<Purchase, PurchaseSearchRequest, PurchaseUpsertRequest, PurchaseUpsertRequest> _service) : base(_service)
        {
        }
    }
}
