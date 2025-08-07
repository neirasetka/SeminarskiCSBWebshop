using AutoMapper;
using CBSWebshopSeminarski.Model.Models;
using CBSWebshopSeminarski.Model.Requests;
using CBSWebshopSeminarski.Services.Interfaces;
using CSBWebshopSeminarski.Database;
using Microsoft.EntityFrameworkCore;

namespace CBSWebshopSeminarski.Services.Services
{
    public class RatesService : IRatesService
    {
        private readonly CocoSunBagsWebshopDbContext _context;
        private readonly IMapper _mapper;
        public RatesService(CocoSunBagsWebshopDbContext context, IMapper mapper)
        {
            _context = context;
            _mapper = mapper;
        }

        public async Task<List<Rate>> Get(RateSearchRequest search)
        {
            var query = _context.Rates.AsQueryable();

            if (search.UserID != 0)
            {
                query = query.Where(i => i.UserID == search.UserID);
            }

            if (search.BagID != 0)
            {
                query = query.Where(i => i.BagID == search.BagID);
            }

            if (search.BeltID != 0)
            {
                query = query.Where(i => i.BeltID == search.BeltID);
            }

            if (search.Rating != 0)
            {
                query = query.Where(i => i.Rating == search.Rating);
            }

            var list = await query.ToListAsync();
            return _mapper.Map<List<Rate>>(list);
        }

        public async Task<Rate> GetById(int ID)
        {
            var entity = await _context.Rates
               .Include(i => i.BagID)
               .Include(i => i.BeltID)
               .Where(i => i.UserID == ID)
               .SingleOrDefaultAsync();

            return _mapper.Map<Rate>(entity);
        }

        public async Task<Rate> Insert(RateUpsertRequest request)
        {
            var entity = _mapper.Map<Rate>(request);
            _context.Set<Rate>().Add(entity);
            await _context.SaveChangesAsync();

            return _mapper.Map<Rate>(entity);
        }

        public async Task<Rate> Update(int ID, RateUpsertRequest request)
        {
            var entity = _context.Set<Rate>().Find(ID);
            _context.Set<Rate>().Attach(entity);
            _context.Set<Rate>().Update(entity);

            _mapper.Map(request, entity);

            await _context.SaveChangesAsync();

            return _mapper.Map<Rate>(entity);
        }

        public async Task<bool> Delete(int ID)
        {
            var rate = await _context.Rates.Where(i => i.UserID == ID).Include(i => i.BagID).FirstOrDefaultAsync();
            if (rate != null)
            {
                _context.Rates.Remove(rate);
                await _context.SaveChangesAsync();
                return true;
            }
            return false;
        }
    }
}
