using AutoMapper;
using CBSWebshopSeminarski.Model.Models;
using CSBWebshopSeminarski.Core.Entities;
using CSBWebshopSeminarski.Database;

namespace CBSWebshopSeminarski.Services.Services
{
    public class RolesService : BaseService<Role, object, Roles>
    {
        public RolesService(CocoSunBagsWebshopDbContext context, IMapper mapper) : base(context, mapper)
        {
        }
    }
}
