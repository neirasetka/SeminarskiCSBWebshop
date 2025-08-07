using CBSWebshopSeminarski.Model.Models;
using CBSWebshopSeminarski.Model.Requests;

namespace CBSWebshopSeminarski.Services.Interfaces
{
    public interface IRatesService
    {
        Task<List<Rate>> Get(RateSearchRequest search);
        Task<Rate> GetById(int ID);
        Task<Rate> Insert(RateUpsertRequest request);
        Task<Rate> Update(int ID, RateUpsertRequest request);
        Task<bool> Delete(int ID);
    }
}
