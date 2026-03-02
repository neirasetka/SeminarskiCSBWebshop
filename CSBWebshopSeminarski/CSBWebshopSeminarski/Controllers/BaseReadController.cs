using CBSWebshopSeminarski.Services.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace CSBWebshopSeminarski.Controllers
{
    [Route("api/[controller]")]
    [ApiController]

    public class BaseReadController<T, Tsearch> : ControllerBase
    {
        private readonly IBaseService<T, Tsearch> _service;
        public BaseReadController(IBaseService<T, Tsearch> service)
        {
            _service = service;
        }

        [HttpGet]
        [Authorize]
        public virtual async Task<List<T>> Get([FromQuery] Tsearch search)
        {
            return await _service.Get(search);
        }
        [HttpGet("{ID:int}")]
        [Authorize]
        public async Task<T> GetById(int ID)
        {
            return await _service.GetById(ID);
        }
    }
}
