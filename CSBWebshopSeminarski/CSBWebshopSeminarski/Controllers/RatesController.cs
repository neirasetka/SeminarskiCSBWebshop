using System.Security.Claims;
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
        public async Task<ActionResult<PagedResult<Rate>>> Get([FromQuery] RateSearchRequest search)
        {
            if (search.UserID != 0)
            {
                var denied = DenyUnlessCanAccessUserRates(search.UserID);
                if (denied != null) return denied;
            }
            else if (search.BagID == 0 && search.BeltID == 0 && !User.IsInRole("Admin"))
            {
                return Forbid();
            }

            return Ok(await _service.Get(search));
        }

        [HttpGet("by-user/{userId}")]
        [Authorize]
        public async Task<ActionResult<PagedResult<Rate>>> GetByUser(int userId)
        {
            var denied = DenyUnlessCanAccessUserRates(userId);
            if (denied != null) return denied;

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

        /// <summary>
        /// User-specific rate lists require auth; non-admins may only access their own UserID.
        /// </summary>
        private ActionResult? DenyUnlessCanAccessUserRates(int userId)
        {
            if (userId <= 0)
                return BadRequest();

            if (!(User.Identity?.IsAuthenticated ?? false))
                return Unauthorized();

            if (!User.IsInRole("Admin"))
            {
                var currentUserId = GetCurrentUserId();
                if (currentUserId != userId)
                    return Forbid();
            }

            return null;
        }

        [HttpPost]
        [Authorize]
        public async Task<ActionResult<Rate>> Insert(RateUpsertRequest request)
        {
            var currentUserId = GetCurrentUserId();
            if (currentUserId <= 0)
            {
                return Unauthorized();
            }

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
            {
                return Forbid();
            }

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
            {
                return Forbid();
            }
            var result = await _service.Delete(ID);
            return Ok(result);
        }
    }
}
