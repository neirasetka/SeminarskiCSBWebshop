using CBSWebshopSeminarski.Model.Models;
using CBSWebshopSeminarski.Model.Requests;
using CBSWebshopSeminarski.Services.Interfaces;

namespace CSBWebshopSeminarski.Controllers
{
    public class BeltTypesController : BaseCRUDController<BeltType, BeltTypeSearchRequest, BeltTypeUpsertRequest, BeltTypeUpsertRequest>
    {
        public BeltTypesController(ICRUDService<BeltType, BeltTypeSearchRequest, BeltTypeUpsertRequest, BeltTypeUpsertRequest> service) : base(service)
        {
        }
    }
}
