using AutoMapper;
using CBSWebshopSeminarski.Model.Models;
using CBSWebshopSeminarski.Services.Interfaces;
using CSBWebshopSeminarski.Core.Entities;
using CSBWebshopSeminarski.Database;
using Microsoft.EntityFrameworkCore;

namespace CBSWebshopSeminarski.Services.Services
{
    public class RecommendationService : IRecommendationService
    {
        private readonly CocoSunBagsWebshopDbContext _context;
        private readonly IMapper _mapper;
        public RecommendationService(CocoSunBagsWebshopDbContext context, IMapper mapper)
        {
            _context = context;
            _mapper = mapper;
        }

        public async Task<List<Belt>> GetRecommendedBelts(int UserID, int take = 3)
        {
            if (UserID <= 0)
            {
                return new List<Belt>();
            }

            var favoriteBeltTypeIds = await _context.Favorites
                .Where(f => f.UserID == UserID && f.BeltID.HasValue)
                .Include(f => f.Belt)
                .Select(f => f.Belt.BeltTypeID)
                .Distinct()
                .ToListAsync();

            if (favoriteBeltTypeIds.Count == 0)
            {
                var ratedTypes = await _context.Rates
                    .Where(r => r.UserID == UserID && r.BeltID != 0 && r.Rating >= 3)
                    .Include(r => r.Belt)
                    .Select(r => r.Belt.BeltTypeID)
                    .Distinct()
                    .ToListAsync();
                favoriteBeltTypeIds = ratedTypes;
            }

            if (favoriteBeltTypeIds.Count == 0)
            {
                return new List<Belt>();
            }

            var purchasedBeltIds = await _context.Purchases
                .Where(p => p.UserID == UserID)
                .Include(p => p.Order)
                .ThenInclude(o => o.OrderItems)
                .SelectMany(p => p.Order.OrderItems)
                .Where(oi => oi.BeltID > 0)
                .Select(oi => oi.BeltID)
                .Distinct()
                .ToListAsync();

            var favoritedBeltIds = await _context.Favorites
                .Where(f => f.UserID == UserID && f.BeltID.HasValue)
                .Select(f => f.BeltID!.Value)
                .Distinct()
                .ToListAsync();

            var candidateBelts = await _context.Belts
                .Where(b => favoriteBeltTypeIds.Contains(b.BeltTypeID)
                            && !purchasedBeltIds.Contains(b.BeltID)
                            && !favoritedBeltIds.Contains(b.BeltID))
                .Include(b => b.User)
                .ToListAsync();

            var selected = candidateBelts
                .OrderBy(_ => Guid.NewGuid())
                .Take(Math.Max(1, take))
                .ToList();

            return _mapper.Map<List<Belt>>(selected);
        }

        public async Task<List<Bag>> GetRecommendedBags(int UserID, int take = 3)
        {
            if (UserID <= 0)
            {
                return new List<Bag>();
            }

            var favoriteBagTypeIds = await _context.Favorites
                .Where(f => f.UserID == UserID && f.BagID.HasValue)
                .Include(f => f.Bag)
                .Select(f => f.Bag.BagTypeID ?? 0)
                .Distinct()
                .ToListAsync();

            if (favoriteBagTypeIds.Count == 0)
            {
                var ratedTypes = await _context.Rates
                    .Where(r => r.UserID == UserID && r.BagID != 0 && r.Rating >= 3)
                    .Include(r => r.Bag)
                    .Select(r => r.Bag.BagTypeID ?? 0)
                    .Distinct()
                    .ToListAsync();
                favoriteBagTypeIds = ratedTypes;
            }

            if (favoriteBagTypeIds.Count == 0)
            {
                return new List<Bag>();
            }

            var purchasedBagIds = await _context.Purchases
                .Where(p => p.UserID == UserID)
                .Include(p => p.Order)
                .ThenInclude(o => o.OrderItems)
                .SelectMany(p => p.Order.OrderItems)
                .Where(oi => oi.BagID > 0)
                .Select(oi => oi.BagID)
                .Distinct()
                .ToListAsync();

            var favoritedBagIds = await _context.Favorites
                .Where(f => f.UserID == UserID && f.BagID.HasValue)
                .Select(f => f.BagID!.Value)
                .Distinct()
                .ToListAsync();

            var candidateBags = await _context.Bags
                .Where(b => favoriteBagTypeIds.Contains(b.BagTypeID ?? 0)
                            && !purchasedBagIds.Contains(b.BagID ?? 0)
                            && !favoritedBagIds.Contains(b.BagID ?? 0))
                .Include(b => b.User)
                .ToListAsync();

            var selected = candidateBags
                .OrderBy(_ => Guid.NewGuid())
                .Take(Math.Max(1, take))
                .ToList();

            return _mapper.Map<List<Bag>>(selected);
        }
    }
}
