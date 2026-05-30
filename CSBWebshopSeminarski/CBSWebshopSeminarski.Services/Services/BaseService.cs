using AutoMapper;
using CBSWebshopSeminarski.Services.Interfaces;
using CSBWebshopSeminarski.Database;
using Microsoft.EntityFrameworkCore;

namespace CBSWebshopSeminarski.Services.Services
{
    public class BaseService<TModel, TSearch, TDatabase> : IBaseService<TModel, TSearch> where TDatabase : class
    {
        protected CocoSunBagsWebshopDbContext _context;
        protected IMapper _mapper;
        public BaseService(CocoSunBagsWebshopDbContext context, IMapper mapper)
        {
            _context = context;
            _mapper = mapper;
        }

        public virtual async Task<List<TModel>> Get(TSearch search)
        {
            IQueryable<TDatabase> query = _context.Set<TDatabase>();
            query = ApplyPagination(query, search);
            var list = await query.ToListAsync();
            return _mapper.Map<List<TModel>>(list);
        }

        protected IQueryable<TDatabase> ApplyPagination(IQueryable<TDatabase> query, TSearch search)
        {
            if (search == null) return query;

            var searchType = search.GetType();
            var pageProp = searchType.GetProperty("Page");
            var pageSizeProp = searchType.GetProperty("PageSize");

            if (pageProp != null && pageSizeProp != null)
            {
                var page = (int?)pageProp.GetValue(search);
                var pageSize = (int?)pageSizeProp.GetValue(search);

                if (page.HasValue && pageSize.HasValue && page.Value > 0 && pageSize.Value > 0)
                {
                    query = query.Skip((page.Value - 1) * pageSize.Value).Take(pageSize.Value);
                }
            }

            return query;
        }

        public virtual async Task<TModel> GetById(int ID)
        {
            var entity = await _context.Set<TDatabase>().FindAsync(ID);
            return _mapper.Map<TModel>(entity);
        }
    }
}
