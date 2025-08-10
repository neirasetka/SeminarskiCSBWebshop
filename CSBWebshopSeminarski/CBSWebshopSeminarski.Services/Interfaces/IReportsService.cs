using CBSWebshopSeminarski.Model.ViewModels;

namespace CBSWebshopSeminarski.Services.Interfaces
{
    public interface IReportsService
    {
        Task<SalesSummaryVM> GetSalesSummary(DateTime? fromDateUtc, DateTime? toDateUtc);
        Task<List<RevenueByDayPointVM>> GetRevenueByDay(DateTime? fromDateUtc, DateTime? toDateUtc);
        Task<List<TopProductVM>> GetTopProducts(DateTime? fromDateUtc, DateTime? toDateUtc, int take = 10);
    }
}