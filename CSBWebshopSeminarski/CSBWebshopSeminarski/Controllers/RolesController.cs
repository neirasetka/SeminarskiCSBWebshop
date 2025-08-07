using CBSWebshopSeminarski.Model.Models;
using CBSWebshopSeminarski.Services.Interfaces;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;

namespace CSBWebshopSeminarski.Controllers
{
    public class RolesController : BaseReadController<Role, object>
    {
        public RolesController(IBaseService<Role, object> service) : base(service)
        {
        }
    }
}
