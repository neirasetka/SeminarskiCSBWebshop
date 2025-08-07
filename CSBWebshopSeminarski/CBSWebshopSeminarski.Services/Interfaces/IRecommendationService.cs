using CBSWebshopSeminarski.Model.Models;

namespace CBSWebshopSeminarski.Services.Interfaces
{
    public interface IRecommendationService
    {
        Task<List<Bag>> GetRecommendedBags(int UserID);
        Task<List<Belt>> GetRecommendedBelts(int UserID);
    }
}
