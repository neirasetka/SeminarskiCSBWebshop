using AutoMapper;
using CBSWebshopSeminarski.Model.Models;
using CBSWebshopSeminarski.Model.Requests;
using CSBWebshopSeminarski.Core.Entities;
using CSBWebshopSeminarski.Database;

namespace CBSWebshopSeminarski.Services.Services
{
    public class RolesService : BaseService<Role, RoleSearchRequest, Roles>
    {
        public RolesService(CocoSunBagsWebshopDbContext context, IMapper mapper) : base(context, mapper)
        {
        }
    }
}
