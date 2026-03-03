using CBSWebshopSeminarski.Model.Models;
using CBSWebshopSeminarski.Model.Requests;
using CBSWebshopSeminarski.Services.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace CSBWebshopSeminarski.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class BagsController : Controller
    {
        private readonly IBagsService _service;
        public BagsController(IBagsService service)
        {
            _service = service;
        }

        [HttpGet]
        public async Task<List<Bag>> Get([FromQuery] BagSearchRequest search)
        {
            return await _service.Get(search);
        }

        [HttpGet("{ID}")]
        public async Task<Bag> GetById(int ID)
        {
            return await _service.GetById(ID);
        }

        [HttpPost]
        [Authorize(Roles = "Admin")]
        public async Task<Bag> Insert(BagUpsertRequest request)
        {
            return await _service.Insert(request);
        }

        [HttpPut("{ID}")]
        [Authorize(Roles = "Admin")]
        public async Task<Bag> Update(int ID, BagUpsertRequest request)
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
