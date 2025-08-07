using CBSWebshopSeminarski.Model.Models;
using CBSWebshopSeminarski.Services.Interfaces;
using CSBWebshopSeminarski.Core.Entities;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;

namespace CSBWebshopSeminarski.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class RecommendationController : ControllerBase
    {
        private readonly IRecommendationService _service;
        public RecommendationController(IRecommendationService service)
        {
            _service = service;
        }

        [HttpGet("GetRecommendedBags")]
        public Task<List<Bag>> GetRecommendedBags(int UserID)
        {
            return _service.GetRecommendedBags(UserID);
        }

        [HttpGet("GetRecommendedBelts")]
        public Task<List<Belt>> GetRecommendedBelts(int UserID)
        {
            return _service.GetRecommendedBelts(UserID);
        }
    }
}
