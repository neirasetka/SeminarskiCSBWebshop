using AutoMapper;
using CBSWebshopSeminarski.Model.Models;
using CBSWebshopSeminarski.Model.Requests;
using CSBWebshopSeminarski.Core.Entities;
using CSBWebshopSeminarski.Database;
using Microsoft.EntityFrameworkCore;

namespace CBSWebshopSeminarski.Services.Services
{
    public class BagTypesService : CRUDService<BagType, BagTypeSearchRequest, BagTypes, BagTypeUpsertRequest, BagTypeUpsertRequest>
    {
        private readonly CocoSunBagsWebshopDbContext _context;
        private readonly IMapper _mapper;
        public BagTypesService(CocoSunBagsWebshopDbContext context, IMapper mapper) : base(context, mapper)
        {
            _context = context;
            _mapper = mapper;
        }

        public override async Task<List<BagType>> Get(BagTypeSearchRequest request)
        {
            var query = _context.BagTypes.AsQueryable().OrderBy(c => c.BagName);

            if (!string.IsNullOrWhiteSpace(request?.BagName))
            {
                query = query.Where(x => x.BagName.StartsWith(request.BagName)).OrderBy(c => c.BagName);
            }
            var list = await query.ToListAsync();

            return _mapper.Map<List<BagType>>(list);
        }

        public override async Task<BagType> GetById(int ID)
        {
            var entity = await _context.BagTypes
              .Where(i => i.BagTypeID == ID)
              .SingleOrDefaultAsync();

            return _mapper.Map<BagType>(entity);
        }

        public override async Task<BagType> Insert(BagTypeUpsertRequest request)
        {
            if (await _context.BagTypes.AnyAsync(i => i.BagName == request.BagName))
            {
                throw new Exception("Bag type already exists!");
            }
            var entity = _mapper.Map<BagTypes>(request);

            _context.Set<BagTypes>().Add(entity);
            await _context.SaveChangesAsync();

            return _mapper.Map<BagType>(entity);
        }

        public override async Task<BagType> Update(int ID, BagTypeUpsertRequest request)
        {
            var vrsta = await _context.BagTypes.FindAsync(ID);
            if (await _context.BagTypes.AnyAsync(i => i.BagName == request.BagName) && request.BagName != vrsta.BagName)
            {
                throw new Exception("Bag type already exists!");
            }

            var entity = _context.Set<BagTypes>().Find(ID);
            _context.Set<BagTypes>().Attach(entity);
            _context.Set<BagTypes>().Update(entity);

            _mapper.Map(request, entity);

            await _context.SaveChangesAsync();

            return _mapper.Map<BagType>(entity);
        }

        public override async Task<bool> Delete(int ID)
        {
            var bagType = await _context.BagTypes.Where(i => i.BagTypeID == ID).FirstOrDefaultAsync();
            var bag = await _context.Bags.Where(i => i.BagTypeID == bagType.BagTypeID).ToListAsync();
            var orderItems = await _context.OrderItems.Where(i => i.Bag != null && i.Bag.BagTypeID == bagType.BagTypeID).ToListAsync();
            var reviews = await _context.Reviews.Where(i => i.Bag.BagTypeID == bagType.BagTypeID).ToListAsync();
            var rates = await _context.Rates.Where(i => i.Bag.BagTypeID == bagType.BagTypeID).ToListAsync();
            var favorites = await _context.Favorites.Where(i => i.Bag.BagTypeID == bagType.BagTypeID).ToListAsync();

            if (bagType != null)
            {
                if (bag.Count > 0)
                {
                    _context.Bags.RemoveRange(bag);
                    if (bag.Count > 0)
                        _context.OrderItems.RemoveRange(orderItems);
                    if (rates.Count > 0)
                        _context.Rates.RemoveRange(rates);
                    if (reviews.Count > 0)
                        _context.Reviews.RemoveRange(reviews);
                    if (favorites.Count > 0)
                        _context.Favorites.RemoveRange(favorites);
                }
                _context.BagTypes.Remove(bagType);
                await _context.SaveChangesAsync();

                return true;
            }
            return false;
        }
    }
}
