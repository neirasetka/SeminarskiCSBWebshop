namespace CBSWebshopSeminarski.Services.Interfaces
{
    public interface IBaseService<T, TSearch>
    {
        Task<List<T>> Get(TSearch search);
        Task<T> GetById(int ID);
    }
}
