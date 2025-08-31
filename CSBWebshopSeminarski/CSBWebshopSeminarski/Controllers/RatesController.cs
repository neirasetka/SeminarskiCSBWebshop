using CBSWebshopSeminarski.Model.Models;
using CBSWebshopSeminarski.Model.Requests;
using CBSWebshopSeminarski.Services.Interfaces;
using CBSWebshopSeminarski.Services.Services;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;

namespace CSBWebshopSeminarski.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class RatesController : Controller
    {
        private readonly IRatesService _service;
        public RatesController(IRatesService service)
        {
            _service = service;
        }

        [HttpGet]
        public async Task<List<Rate>> Get([FromQuery] RateSearchRequest search)
        {
            return await _service.Get(search);
        }

        [HttpGet("by-user/{userId}")]
        public async Task<List<Rate>> GetByUser(int userId)
        {
            var search = new RateSearchRequest { UserID = userId };
            return await _service.Get(search);
        }

        [HttpGet("{ID}")]
        public async Task<Rate> GetById(int ID)
        {
            return await _service.GetById(ID);
        }

        [HttpPost]
        public async Task<Rate> Insert(RateUpsertRequest request)
        {
            return await _service.Insert(request);
        }

        [HttpPut("{ID}")]
        public async Task<Rate> Update(int ID, RateUpsertRequest request)
        {
            return await _service.Update(ID, request);
        }

        [HttpDelete("{ID}")]
        public async Task<bool> Delete(int ID)
        {
            return await _service.Delete(ID);
        }
    }
}
