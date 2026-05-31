using CBSWebshopSeminarski.Model.Models;
using CBSWebshopSeminarski.Model.Requests;
using CBSWebshopSeminarski.Services.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace CSBWebshopSeminarski.Controllers
{
    public class RolesController : BaseReadController<Role, RoleSearchRequest>
    {
        public RolesController(IBaseService<Role, RoleSearchRequest> service) : base(service)
        {
        }

        [HttpGet]
        [Authorize(Roles = "Admin")]
        public override async Task<PagedResult<Role>> Get([FromQuery] RoleSearchRequest search)
        {
            return await base.Get(search);
        }

        [HttpGet("{ID:int}")]
        [Authorize(Roles = "Admin")]
        public override async Task<Role> GetById(int ID)
        {
            return await base.GetById(ID);
        }
    }
}
