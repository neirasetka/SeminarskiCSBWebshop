using CBSWebshopSeminarski.Model.Models;
using CBSWebshopSeminarski.Model.Requests;

namespace CBSWebshopSeminarski.Services.Interfaces
{
    public interface IBaseService<T, TSearch> where TSearch : PagedSearchRequest
    {
        Task<PagedResult<T>> Get(TSearch search);
        Task<T> GetById(int ID);
    }
}
