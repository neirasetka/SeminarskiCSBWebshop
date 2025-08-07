using CBSWebshopSeminarski.Model.Models;
using CBSWebshopSeminarski.Model.Requests;

namespace CBSWebshopSeminarski.Services.Interfaces
{
    public interface IBagsService
    {
        Task<float> GetAverage(int ID);
        Task<List<Bag>> Get(BagSearchRequest search);
        Task<Bag> GetById(int ID);
        Task<Bag> Insert(BagUpsertRequest request);
        Task<Bag> Update(int ID, BagUpsertRequest request);
        Task<bool> Delete(int ID);
    }
}
