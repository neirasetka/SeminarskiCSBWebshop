using CBSWebshopSeminarski.Model.Models;
using CSBWebshopSeminarski.Core.Entities;

namespace CBSWebshopSeminarski.Services.Interfaces
{
    public interface IRecommendationService
    {
        Task<List<Bag>> GetRecommendedBags(int UserID, int take = 3);
        Task<List<Belt>> GetRecommendedBelts(int UserID, int take = 3);
    }
}
