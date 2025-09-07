using CBSWebshopSeminarski.Model.Models;
using CBSWebshopSeminarski.Services.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Security.Claims;

namespace CSBWebshopSeminarski.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    [Authorize]
    public class RecommendationController : ControllerBase
    {
        private readonly IRecommendationService _service;
        public RecommendationController(IRecommendationService service)
        {
            _service = service;
        }

        [HttpGet("GetRecommendedBags")]
        public Task<List<Bag>> GetRecommendedBags([FromQuery] int? take)
        {
            var userIdClaim = User.FindFirstValue(ClaimTypes.NameIdentifier);
            var userId = int.TryParse(userIdClaim, out var id) ? id : 0;
            var howMany = take.HasValue && take.Value > 0 ? take.Value : 3;
            return _service.GetRecommendedBags(userId, howMany);
        }

        [HttpGet("GetRecommendedBelts")]
        public Task<List<Belt>> GetRecommendedBelts([FromQuery] int? take)
        {
            var userIdClaim = User.FindFirstValue(ClaimTypes.NameIdentifier);
            var userId = int.TryParse(userIdClaim, out var id) ? id : 0;
            var howMany = take.HasValue && take.Value > 0 ? take.Value : 3;
            return _service.GetRecommendedBelts(userId, howMany);
        }
    }
}
