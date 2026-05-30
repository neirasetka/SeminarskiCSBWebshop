namespace CBSWebshopSeminarski.Services.Interfaces
{
    public interface ICRUDService<T, TSearch, TInsert, TUpdate> : IBaseService<T, TSearch>
        where TSearch : CBSWebshopSeminarski.Model.Requests.PagedSearchRequest
    {
        Task<T> Insert(TInsert request);
        Task<T> Update(int ID, TUpdate request);
        Task<bool> Delete(int ID);
    }
}
