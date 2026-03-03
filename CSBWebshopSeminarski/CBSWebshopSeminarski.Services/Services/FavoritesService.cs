using AutoMapper;
using CBSWebshopSeminarski.Model.Models;
using CBSWebshopSeminarski.Model.Requests;
using CSBWebshopSeminarski.Core.Entities;
using CSBWebshopSeminarski.Database;
using Microsoft.EntityFrameworkCore;

namespace CBSWebshopSeminarski.Services.Services
{
    public class FavoritesService : CRUDService<Favorite, FavoriteSearchRequest, Favorites, FavoriteUpsertRequest, FavoriteUpsertRequest>
    {
        private new readonly CocoSunBagsWebshopDbContext _context;
        private new readonly IMapper _mapper;

        public FavoritesService(CocoSunBagsWebshopDbContext context, IMapper mapper) : base(context, mapper)
        {
            _context = context;
            _mapper = mapper;
        }
        public override async Task<List<Favorite>> Get(FavoriteSearchRequest request)
        {
            var query = _context.Favorites.AsQueryable();

            if (request.UserID != 0)
            {
                query = (IOrderedQueryable<Favorites>)query.Where(x => x.UserID == request.UserID);
            }

            if (request.UserID != 0 && request.BagID != 0)
            {
                query = (IOrderedQueryable<Favorites>)query.Where(x => x.UserID == request.UserID && x.BagID == request.BagID);
            }

            if (request.UserID != 0 && request.BeltID != 0)
            {
                query = (IOrderedQueryable<Favorites>)query.Where(x => x.UserID == request.UserID && x.BeltID == request.BeltID);
            }

            var list = await query.ToListAsync();
            return _mapper.Map<List<Favorite>>(list);
        }
        public override async Task<Favorite> Update(int ID, FavoriteUpsertRequest request)
        {
            var entity = _context.Set<Favorites>().Find(ID);
            if (entity == null)
                throw new ArgumentException($"Favorite with ID {ID} not found.");
            _context.Set<Favorites>().Attach(entity);
            _context.Set<Favorites>().Update(entity);

            _mapper.Map(request, entity);

            await _context.SaveChangesAsync();

            return _mapper.Map<Favorite>(entity);
        }
    }
}
