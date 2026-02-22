using CBSWebshopSeminarski.Model.Models;
using CBSWebshopSeminarski.Model.Requests;
using CBSWebshopSeminarski.Services.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace CSBWebshopSeminarski.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class BeltsController : Controller
    {
        private readonly IBeltsService _service;
        public BeltsController(IBeltsService service)
        {
            _service = service;
        }

        [HttpGet]
        public async Task<List<Belt>> Get([FromQuery] BeltSearchRequest? search = null)
        {
            return await _service.Get(search ?? new BeltSearchRequest());
        }

        [HttpGet("{ID}")]
        public async Task<Belt> GetById(int ID)
        {
            return await _service.GetById(ID);
        }

        [HttpPost]
        [Authorize(Roles = "Admin, Buyer")]
        public async Task<Belt> Insert(BeltUpsertRequest request)
        {
            return await _service.Insert(request);
        }

        [HttpPut("{ID}")]
        [Authorize(Roles = "Admin")]
        public async Task<Belt> Update(int ID, BeltUpsertRequest request)
        {
            return await _service.Update(ID, request);
        }

        [HttpDelete("{ID}")]
        [Authorize(Roles = "Admin")]
        public async Task<bool> Delete(int ID)
        {
            return await _service.Delete(ID);
        }

        [HttpGet("{ID}/GetAverage")]
        public async Task<float> GetAverageRating(int ID)
        {
            return await _service.GetAverage(ID);
        }
    }
}
