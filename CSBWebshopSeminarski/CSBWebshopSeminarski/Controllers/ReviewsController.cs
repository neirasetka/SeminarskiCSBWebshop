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
        public ReviewsController(IReviewsService service)
        {
            _service = service;
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
        public async Task<Review> Insert(ReviewUpsertRequest request)
        {
            return await _service.Insert(request);
        }

        [HttpPut("{ID}")]
        public async Task<Review> Update(int ID, ReviewUpsertRequest request)
        {
            return await _service.Update(ID, request);
        }

        [HttpDelete("{ID}")]
        public async Task<bool> Delete(int ID)
        {
            return await _service.Delete(ID);
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
