using AutoMapper;
using CBSWebshopSeminarski.Model.Models;
using CBSWebshopSeminarski.Model.Requests;
using CBSWebshopSeminarski.Services.Interfaces;
using CSBWebshopSeminarski.Database;
using Microsoft.EntityFrameworkCore;

namespace CBSWebshopSeminarski.Services.Services
{
    public class BaseService<TModel, TSearch, TDatabase> : IBaseService<TModel, TSearch>
        where TDatabase : class
        where TSearch : PagedSearchRequest
    {
        protected CocoSunBagsWebshopDbContext _context;
        protected IMapper _mapper;

        public BaseService(CocoSunBagsWebshopDbContext context, IMapper mapper)
        {
            _context = context;
            _mapper = mapper;
        }

        public virtual async Task<PagedResult<TModel>> Get(TSearch search)
        {
            IQueryable<TDatabase> query = _context.Set<TDatabase>();
            return await ToPagedResultAsync(query, search);
        }

        protected Task<PagedResult<TModel>> ToPagedResultAsync(IQueryable<TDatabase> query, PagedSearchRequest? search) =>
            PagedQueryHelper.ToPagedResultAsync<TDatabase, TModel>(query, search, _mapper);

        public virtual async Task<TModel> GetById(int ID)
        {
            var entity = await _context.Set<TDatabase>().FindAsync(ID);
            return _mapper.Map<TModel>(entity);
        }
    }
}
