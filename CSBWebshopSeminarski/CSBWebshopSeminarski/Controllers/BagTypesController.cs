using CBSWebshopSeminarski.Model.Models;
using CBSWebshopSeminarski.Model.Requests;
using CBSWebshopSeminarski.Services.Interfaces;

namespace CSBWebshopSeminarski.Controllers
{
    public class BagTypesController : BaseCRUDController<BagType, BagTypeSearchRequest, BagTypeUpsertRequest, BagTypeUpsertRequest>
    {
        public BagTypesController(ICRUDService<BagType, BagTypeSearchRequest, BagTypeUpsertRequest, BagTypeUpsertRequest> service) : base(service)
        {
        }
    }
}
