using System.Security.Claims;
using CBSWebshopSeminarski.Model.Models;
using CBSWebshopSeminarski.Model.Requests;
using CBSWebshopSeminarski.Services.Exceptions;
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
        public async Task<ActionResult<PagedResult<Rate>>> Get([FromQuery] RateSearchRequest search)
        {
            if (search.UserID != 0)
            {
                if (search.UserID <= 0)
                    throw new ValidationException("UserID must be a positive integer.");

                if (!(User.Identity?.IsAuthenticated ?? false))
                    return Unauthorized();

                if (!User.IsInRole("Admin"))
                {
                    var currentUserId = GetCurrentUserId();
                    if (currentUserId != search.UserID)
                        throw new ForbiddenException("Access denied.");
                }
            }
            else if (search.BagID == 0 && search.BeltID == 0 && !User.IsInRole("Admin"))
            {
                throw new ForbiddenException("Access denied.");
            }

            return Ok(await _service.Get(search));
        }

        [HttpGet("by-user/{userId}")]
        [Authorize]
        public async Task<ActionResult<PagedResult<Rate>>> GetByUser(int userId)
        {
            EnsureCanAccessUserRates(userId);

            var search = new RateSearchRequest { UserID = userId };
            return Ok(await _service.Get(search));
        }

        [HttpGet("{ID}")]
        public async Task<Rate> GetById(int ID)
        {
            return await _service.GetById(ID);
        }

        private int GetCurrentUserId()
        {
            var claim = User.FindFirstValue(ClaimTypes.NameIdentifier);
            return int.TryParse(claim, out var id) ? id : 0;
        }

        private void EnsureCanAccessUserRates(int userId)
        {
            if (userId <= 0)
                throw new ValidationException("UserID must be a positive integer.");

            if (!User.IsInRole("Admin"))
            {
                var currentUserId = GetCurrentUserId();
                if (currentUserId != userId)
                    throw new ForbiddenException("Access denied.");
            }
        }

        [HttpPost]
        [Authorize]
        public async Task<ActionResult<Rate>> Insert(RateUpsertRequest request)
        {
            var currentUserId = GetCurrentUserId();
            if (currentUserId <= 0)
                throw new ForbiddenException("Access denied.");

            request.UserID = currentUserId;
            return Ok(await _service.Insert(request));
        }

        [HttpPut("{ID}")]
        [Authorize]
        public async Task<ActionResult<Rate>> Update(int ID, RateUpsertRequest request)
        {
            var existing = await _service.GetById(ID);
            var authorizationResult = await _authorizationService.AuthorizeAsync(User, existing, "CanModifyRate");
            if (!authorizationResult.Succeeded)
                throw new ForbiddenException("Access denied.");

            request.UserID = existing.UserID;
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
                throw new ForbiddenException("Access denied.");
            var result = await _service.Delete(ID);
            return Ok(result);
        }
    }
}
