using CBSWebshopSeminarski.Model.Models;
using CBSWebshopSeminarski.Model.Requests;
using CBSWebshopSeminarski.Model.ViewModels;
using CBSWebshopSeminarski.Services.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace CSBWebshopSeminarski.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    [Authorize(Roles = "Admin")]
    public class ReportsController : ControllerBase
    {
        private readonly IReportsService _reportsService;

        public ReportsController(IReportsService reportsService)
        {
            _reportsService = reportsService;
        }

        [HttpGet("SalesSummary")]
        public async Task<SalesSummaryVM> SalesSummary([FromQuery] ReportsSearchRequest request)
        {
            return await _reportsService.GetSalesSummary(request.FromDateUtc, request.ToDateUtc);
        }

        [HttpGet("RevenueByDay")]
        public async Task<List<RevenueByDayPointVM>> RevenueByDay([FromQuery] ReportsSearchRequest request)
        {
            return await _reportsService.GetRevenueByDay(request.FromDateUtc, request.ToDateUtc);
        }

        [HttpGet("TopProducts")]
        public async Task<List<TopProductVM>> TopProducts([FromQuery] ReportsSearchRequest request)
        {
            var take = request.Take.HasValue && request.Take.Value > 0 ? request.Take.Value : 10;
            return await _reportsService.GetTopProducts(request.FromDateUtc, request.ToDateUtc, take);
        }

        [HttpGet("TopSellingBags")]
        public async Task<List<Bag>> TopSellingBags([FromQuery] int? take)
        {
            var howMany = take.HasValue && take.Value > 0 ? take.Value : 6;
            return await _reportsService.GetTopSellingBags(howMany);
        }
    }
}
