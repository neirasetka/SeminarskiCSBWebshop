using CBSWebshopSeminarski.Model.Models;
using CBSWebshopSeminarski.Model.Requests;
using CBSWebshopSeminarski.Services.Interfaces;

namespace CSBWebshopSeminarski.Controllers
{
    public class RolesController : BaseReadController<Role, RoleSearchRequest>
    {
        public RolesController(IBaseService<Role, RoleSearchRequest> service) : base(service)
        {
        }
    }
}
