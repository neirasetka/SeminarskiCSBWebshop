using CBSWebshopSeminarski.Model.Models;

namespace CBSWebshopSeminarski.Services.Interfaces
{
    public interface IRecommendationService
    {
        Task<List<RecommendedProductDto>> GetRecommendedBags(int userId, int take = 3);
        Task<List<RecommendedProductDto>> GetRecommendedBelts(int userId, int take = 3);
    }
}
