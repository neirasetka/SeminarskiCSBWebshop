using AutoMapper;
using CBSWebshopSeminarski.Model.Models;
using CBSWebshopSeminarski.Model.Requests;
using CBSWebshopSeminarski.Services.Interfaces;
using CSBWebshopSeminarski.Core.Entities;
using CSBWebshopSeminarski.Database;
using Microsoft.EntityFrameworkCore;

namespace CBSWebshopSeminarski.Services.Services
{
    public class BagsService : CRUDService<Bag, BagSearchRequest, Bags, BagUpsertRequest, BagUpsertRequest>, IBagsService
    {
        private readonly CocoSunBagsWebshopDbContext _context;
        private readonly IMapper _mapper;
        public BagsService(CocoSunBagsWebshopDbContext context, IMapper mapper) : base(context, mapper)
        {
            _context = context;
            _mapper = mapper;
        }
        public override async Task<List<Bag>> Get(BagSearchRequest request)
        {
            var query = _context.Bags.Include(i => i.User).AsQueryable().OrderBy(c => c.BagName);

            if (request.UserID != 0)
            {
                query = query.Where(x => x.UserID == request.UserID).Include(i => i.User).OrderBy(c => c.BagName);
            }

            if (request?.BagTypeID.HasValue == true)
            {
                query = query.Where(x => x.BagTypeID == request.BagTypeID).Include(i => i.BagType).Include(i => i.User).OrderBy(c => c.BagType);
            }

            if (!string.IsNullOrWhiteSpace(request?.BagName))
            {
                query = query.Where(x => x.BagName.Contains(request.BagName)).Include(i => i.User).OrderBy(c => c.BagName);
            }
            var list = await query.ToListAsync();

            return _mapper.Map<List<Bag>>(list);
        }

        public override async Task<Bag> Insert(BagUpsertRequest request)
        {
            var entity = _mapper.Map<Bags>(request);

            // Normalize optional foreign keys coming from the client.
            // Frontend sends 0 / omits values to mean "no type / no user".
            if (entity.BagTypeID.HasValue && entity.BagTypeID.Value == 0)
            {
                entity.BagTypeID = null;
            }
            if (entity.UserID.HasValue && entity.UserID.Value == 0)
            {
                entity.UserID = null;
            }

            if (!string.IsNullOrWhiteSpace(request.Image))
                entity.Image = Convert.FromBase64String(request.Image);

            _context.Set<Bags>().Add(entity);
            await _context.SaveChangesAsync();

            return _mapper.Map<Bag>(entity);
        }

        public override async Task<Bag> Update(int ID, BagUpsertRequest request)
        {
            var entity = await _context.Bags.FindAsync(ID);
            if (entity == null)
            {
                throw new Exception($"Bag with ID {ID} not found.");
            }

            // Enforce unique name across bags (excluding the current one).
            if (await _context.Bags.AnyAsync(i => i.BagName == request.BagName && i.BagID != ID))
            {
                throw new Exception("Bag already exists!");
            }

            // Update scalar fields directly to avoid overwriting important values with defaults/nulls.
            entity.BagName = request.BagName;
            entity.Code = request.Code;
            entity.Price = request.Price;
            if (!string.IsNullOrWhiteSpace(request.Description))
            {
                entity.Description = request.Description;
            }

            // BagType is optional – treat 0 as "no type".
            if (request.BagTypeID == 0)
            {
                entity.BagTypeID = null;
            }
            else
            {
                entity.BagTypeID = request.BagTypeID;
            }

            // Only overwrite the image if the client actually sent one (base64 string).
            if (!string.IsNullOrWhiteSpace(request.Image))
            {
                entity.Image = Convert.FromBase64String(request.Image);
            }

            // Do NOT change UserID here – keep the existing owner.

            await _context.SaveChangesAsync();

            return _mapper.Map<Bag>(entity);
        }

        public override async Task<bool> Delete(int ID)
        {
            var bag = await _context.Bags.Where(c => c.BagID == ID).FirstOrDefaultAsync();

            if (bag != null)
            {

                var favorites = await _context.Favorites.Where(i => i.BagID == ID).ToListAsync();
                if (favorites != null)
                    _context.Favorites.RemoveRange(favorites);

                var reviews = await _context.Reviews.Where(i => i.BagID == ID).ToListAsync();
                if (reviews != null)
                    _context.Reviews.RemoveRange(reviews);

                var orders = await _context.OrderItems.Where(i => i.OrderID == ID).ToListAsync();
                if (orders != null)
                    _context.OrderItems.RemoveRange(orders);
                var rates = await _context.Rates.Where(i => i.UserID == ID).ToListAsync();
                if (rates != null)
                    _context.Rates.RemoveRange(rates);
                await _context.SaveChangesAsync();

                _context.Bags.Remove(bag);
                await _context.SaveChangesAsync();

                return true;
            }
            return false;
        }
        public async Task<float> GetAverage(int BagID)
        {
            var list = await _context.Rates.Where(i => i.BagID == BagID).ToListAsync();
            if (list.Count() != 0)
            {
                return (float)list.Average(i => i.Rating);
            }
            return 0;
        }
    }
}
