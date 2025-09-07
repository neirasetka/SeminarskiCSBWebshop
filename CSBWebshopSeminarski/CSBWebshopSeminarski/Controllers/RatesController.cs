using CBSWebshopSeminarski.Model.Models;
using CBSWebshopSeminarski.Model.Requests;
using CBSWebshopSeminarski.Services.Interfaces;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Authorization;

namespace CSBWebshopSeminarski.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class RatesController : Controller
    {
        private readonly IRatesService _service;
        private readonly IAuthorizationService _authorizationService;
        public RatesController(IRatesService service, IAuthorizationService authorizationService)
        {
            _service = service;
            _authorizationService = authorizationService;
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
        [Authorize]
        public async Task<Rate> Insert(RateUpsertRequest request)
        {
            return await _service.Insert(request);
        }

        [HttpPut("{ID}")]
        [Authorize]
        public async Task<ActionResult<Rate>> Update(int ID, RateUpsertRequest request)
        {
            var existing = await _service.GetById(ID);
            var authorizationResult = await _authorizationService.AuthorizeAsync(User, existing, "CanModifyRate");
            if (!authorizationResult.Succeeded)
            {
                return Forbid();
            }
            var updated = await _service.Update(ID, request);
            return Ok(updated);
        }

        [HttpDelete("{ID}")]
        [Authorize]
        public async Task<ActionResult<bool>> Delete(int ID)
        {
            var existing = await _service.GetById(ID);
            var authorizationResult = await _authorizationService.AuthorizeAsync(User, existing, "CanModifyRate");
            if (!authorizationResult.Succeeded)
            {
                return Forbid();
            }
            var result = await _service.Delete(ID);
            return Ok(result);
        }
    }
}
