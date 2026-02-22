using AutoMapper;
using CBSWebshopSeminarski.Model.Models;
using CBSWebshopSeminarski.Model.Requests;
using CBSWebshopSeminarski.Services.Interfaces;
using CSBWebshopSeminarski.Core.Entities;
using CSBWebshopSeminarski.Database;
using Microsoft.EntityFrameworkCore;

namespace CBSWebshopSeminarski.Services.Services
{
    public class BeltsService : CRUDService<Belt, BeltSearchRequest, Belts, BeltUpsertRequest, BeltUpsertRequest>, IBeltsService
    {
        private readonly CocoSunBagsWebshopDbContext _context;
        private readonly IMapper _mapper;
        public BeltsService(CocoSunBagsWebshopDbContext context, IMapper mapper) : base(context, mapper)
        {
            _context = context;
            _mapper = mapper;
        }
        public override async Task<List<Belt>> Get(BeltSearchRequest request)
        {
            request ??= new BeltSearchRequest();
            var query = _context.Belts.Include(i => i.User).Include(i => i.BeltType).AsQueryable().OrderBy(c => c.BeltName);

            if (request.UserID != 0)
            {
                query = query.Where(x => x.UserID == request.UserID).Include(i => i.User).OrderBy(c => c.BeltName);
            }

            if (request.BeltTypeID.HasValue)
            {
                query = query.Where(x => x.BeltTypeID == request.BeltTypeID).Include(i => i.BeltType).Include(i => i.User).OrderBy(c => c.BeltTypeID);
            }

            if (!string.IsNullOrWhiteSpace(request.BeltName))
            {
                query = query.Where(x => x.BeltName.Contains(request.BeltName)).Include(i => i.User).OrderBy(c => c.BeltName);
            }
            var list = await query.ToListAsync();

            return _mapper.Map<List<Belt>>(list);
        }

        public override async Task<Belt> Insert(BeltUpsertRequest request)
        {
            var entity = _mapper.Map<Belts>(request);

            _context.Set<Belts>().Add(entity);
            await _context.SaveChangesAsync();

            return _mapper.Map<Belt>(entity);
        }
        public override async Task<Belt> Update(int ID, BeltUpsertRequest request)
        {
            var proizvod = await _context.Belts.FindAsync(ID);
            if (await _context.Belts.AnyAsync(i => i.BeltName == request.BeltName) && request.BeltName != proizvod.BeltName)
            {
                throw new Exception("Belt already exists!");
            }

            var entity = _context.Set<Belts>().Find(ID);
            _context.Set<Belts>().Attach(entity);
            _context.Set<Belts>().Update(entity);

            _mapper.Map(request, entity);

            await _context.SaveChangesAsync();

            return _mapper.Map<Belt>(entity);
        }
        public override async Task<bool> Delete(int ID)
        {
            var belt = await _context.Belts.Where(c => c.BeltID == ID).FirstOrDefaultAsync();

            if (belt != null)
            {

                var favorites = await _context.Favorites.Where(i => i.BeltID == ID).ToListAsync();
                if (favorites != null)
                    _context.Favorites.RemoveRange(favorites);

                var reviews = await _context.Reviews.Where(i => i.BeltID == ID).ToListAsync();
                if (reviews != null)
                    _context.Reviews.RemoveRange(reviews);

                var orders = await _context.OrderItems.Where(i => i.BeltID == ID).ToListAsync();
                if (orders != null)
                    _context.OrderItems.RemoveRange(orders);
                var rates = await _context.Rates.Where(i => i.BeltID == ID).ToListAsync();
                if (rates != null)
                    _context.Rates.RemoveRange(rates);
                await _context.SaveChangesAsync();

                _context.Belts.Remove(belt);
                await _context.SaveChangesAsync();

                return true;
            }
            return false;
        }
        public async Task<float> GetAverage(int BeltID)
        {
            var list = await _context.Rates.Where(i => i.BeltID == BeltID).ToListAsync();
            if (list.Count() != 0)
            {
                return (float)list.Average(i => i.Rating);
            }
            return 0;
        }
    }
}
