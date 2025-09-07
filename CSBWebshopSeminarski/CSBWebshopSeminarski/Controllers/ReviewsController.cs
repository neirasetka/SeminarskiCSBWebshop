using CBSWebshopSeminarski.Model.Models;
using CBSWebshopSeminarski.Model.Requests;
using CBSWebshopSeminarski.Services.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace CSBWebshopSeminarski.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class ReviewsController : Controller
    {
        private readonly IReviewsService _service;
        private readonly IAuthorizationService _authorizationService;
        public ReviewsController(IReviewsService service, IAuthorizationService authorizationService)
        {
            _service = service;
            _authorizationService = authorizationService;
        }

        [HttpGet]
        public async Task<List<Review>> Get([FromQuery] ReviewSearchRequest search)
        {
            return await _service.Get(search);
        }

        [HttpGet("{ID}")]
        public async Task<Review> GetById(int ID)
        {
            return await _service.GetById(ID);
        }

        [HttpPost]
        [Authorize]
        public async Task<Review> Insert(ReviewUpsertRequest request)
        {
            return await _service.Insert(request);
        }

        [HttpPut("{ID}")]
        [Authorize]
        public async Task<ActionResult<Review>> Update(int ID, ReviewUpsertRequest request)
        {
            var existing = await _service.GetById(ID);
            var authorizationResult = await _authorizationService.AuthorizeAsync(User, existing, "CanModifyReview");
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
            var authorizationResult = await _authorizationService.AuthorizeAsync(User, existing, "CanModifyReview");
            if (!authorizationResult.Succeeded)
            {
                return Forbid();
            }
            var result = await _service.Delete(ID);
            return Ok(result);
        }

        [Authorize(Roles = "Admin")]
        [HttpPost("{id}/approve")]
        public async Task<Review> Approve(int id)
        {
            return await _service.ApproveAsync(id);
        }

        [Authorize(Roles = "Admin")]
        [HttpPost("{id}/reject")]
        public async Task<Review> Reject(int id)
        {
            return await _service.RejectAsync(id);
        }

        [Authorize(Roles = "Admin")]
        [HttpPost("{id}/pending")]
        public async Task<Review> SetPending(int id)
        {
            return await _service.SetPendingAsync(id);
        }
    }
}
