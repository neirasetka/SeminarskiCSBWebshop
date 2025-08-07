using CBSWebshopSeminarski.Model.Models;
using CBSWebshopSeminarski.Model.Requests;

namespace CBSWebshopSeminarski.Services.Interfaces
{
    public interface IBeltsService
    {
        Task<float> GetAverage(int ID);
        Task<List<Belt>> Get(BeltSearchRequest search);
        Task<Belt> GetById(int ID);
        Task<Belt> Insert(BeltUpsertRequest request);
        Task<Belt> Update(int ID, BeltUpsertRequest request);
        Task<bool> Delete(int ID);
    }
}
