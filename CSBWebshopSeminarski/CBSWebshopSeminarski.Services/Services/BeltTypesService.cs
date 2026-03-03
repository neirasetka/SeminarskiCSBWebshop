using AutoMapper;
using CBSWebshopSeminarski.Model.Models;
using CBSWebshopSeminarski.Model.Requests;
using CSBWebshopSeminarski.Core.Entities;
using CSBWebshopSeminarski.Database;
using Microsoft.EntityFrameworkCore;

namespace CBSWebshopSeminarski.Services.Services
{
    public class BeltTypesService : CRUDService<BeltType, BeltTypeSearchRequest, BeltTypes, BeltTypeUpsertRequest, BeltTypeUpsertRequest>
    {
        private readonly CocoSunBagsWebshopDbContext _context;
        private readonly IMapper _mapper;
        public BeltTypesService(CocoSunBagsWebshopDbContext context, IMapper mapper) : base(context, mapper)
        {
            _context = context;
            _mapper = mapper;
        }
        public override async Task<List<BeltType>> Get(BeltTypeSearchRequest request)
        {
            var query = _context.BeltTypes.AsQueryable().OrderBy(c => c.BeltName);

            if (!string.IsNullOrWhiteSpace(request?.BeltName))
            {
                query = query.Where(x => x.BeltName.StartsWith(request.BeltName)).OrderBy(c => c.BeltName);
            }
            var list = await query.ToListAsync();

            return _mapper.Map<List<BeltType>>(list);
        }
        public override async Task<BeltType> GetById(int ID)
        {
            var entity = await _context.BeltTypes
              .Where(i => i.BeltTypeID == ID)
              .SingleOrDefaultAsync();

            return _mapper.Map<BeltType>(entity);

        }
        public override async Task<BeltType> Insert(BeltTypeUpsertRequest request)
        {
            if (await _context.BeltTypes.AnyAsync(i => i.BeltName == request.BeltName))
            {
                throw new Exception("Belt already exists!");
            }
            var entity = _mapper.Map<BeltTypes>(request);

            _context.Set<BeltTypes>().Add(entity);
            await _context.SaveChangesAsync();

            return _mapper.Map<BeltType>(entity);
        }
        public override async Task<BeltType> Update(int ID, BeltTypeUpsertRequest request)
        {
            var vrsta = await _context.BeltTypes.FindAsync(ID);
            if (await _context.BeltTypes.AnyAsync(i => i.BeltName == request.BeltName) && request.BeltName != vrsta.BeltName)
            {
                throw new Exception("Belt already exists!");
            }

            var entity = _context.Set<BeltTypes>().Find(ID);
            _context.Set<BeltTypes>().Attach(entity);
            _context.Set<BeltTypes>().Update(entity);

            _mapper.Map(request, entity);

            await _context.SaveChangesAsync();

            return _mapper.Map<BeltType>(entity);
        }
        public override async Task<bool> Delete(int ID)
        {
            var beltType = await _context.BeltTypes.Where(i => i.BeltTypeID == ID).FirstOrDefaultAsync();
            var belt = await _context.Belts.Where(i => i.BeltTypeID == beltType.BeltTypeID).ToListAsync();
            var orderItems = await _context.OrderItems.Where(i => i.Belt != null && i.Belt.BeltTypeID == beltType.BeltTypeID).ToListAsync();
            var reviews = await _context.Reviews.Where(i => i.Belt.BeltTypeID == beltType.BeltTypeID).ToListAsync();
            var rates = await _context.Rates.Where(i => i.Belt.BeltTypeID == beltType.BeltTypeID).ToListAsync();
            var favorites = await _context.Favorites.Where(i => i.Belt.BeltTypeID == beltType.BeltTypeID).ToListAsync();

            if (beltType != null)
            {
                if (belt.Count > 0)
                {
                    _context.Belts.RemoveRange(belt);
                    if (orderItems.Count > 0)
                        _context.OrderItems.RemoveRange(orderItems);
                    if (rates.Count > 0)
                        _context.Rates.RemoveRange(rates);
                    if (reviews.Count > 0)
                        _context.Reviews.RemoveRange(reviews);
                    if (favorites.Count > 0)
                        _context.Favorites.RemoveRange(favorites);
                }
                _context.BeltTypes.Remove(beltType);
                await _context.SaveChangesAsync();

                return true;
            }
            return false;
        }
    }
}
