using CBSWebshopSeminarski.Model.Models;
using CBSWebshopSeminarski.Model.Requests;

namespace CBSWebshopSeminarski.Services.Interfaces
{
    public interface IReviewsService
    {
        Task<List<Review>> Get(ReviewSearchRequest search);
        Task<Review> GetById(int ID);
        Task<Review> Insert(ReviewUpsertRequest request);
        Task<Review> Update(int ID, ReviewUpsertRequest request);
        Task<bool> Delete(int ID);
    }
}
