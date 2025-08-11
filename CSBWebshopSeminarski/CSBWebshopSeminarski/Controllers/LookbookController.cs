using CBSWebshopSeminarski.Model.Models;
using CBSWebshopSeminarski.Model.Requests;
using CBSWebshopSeminarski.Services.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace CSBWebshopSeminarski.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class LookbookController : Controller
    {
        private readonly ILookbookService _service;
        public LookbookController(ILookbookService service)
        {
            _service = service;
        }

        [HttpGet]
        public async Task<List<LookbookItem>> Get([FromQuery] LookbookSearchRequest search)
        {
            return await _service.Get(search);
        }

        [HttpGet("{ID}")]
        public async Task<LookbookItem> GetById(int ID)
        {
            return await _service.GetById(ID);
        }

        [HttpPost]
        [Authorize(Roles = "Admin")]
        public async Task<LookbookItem> Insert([FromBody] LookbookUpsertRequest request)
        {
            return await _service.Insert(request);
        }

        [HttpPut("{ID}")]
        [Authorize(Roles = "Admin")]
        public async Task<LookbookItem> Update(int ID, [FromBody] LookbookUpsertRequest request)
        {
            return await _service.Update(ID, request);
        }

        [HttpDelete("{ID}")]
        [Authorize(Roles = "Admin")]
        public async Task<bool> Delete(int ID)
        {
            return await _service.Delete(ID);
        }
    }
}