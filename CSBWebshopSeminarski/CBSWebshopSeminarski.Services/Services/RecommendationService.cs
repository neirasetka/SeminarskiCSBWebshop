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
        public async Task<List<Belt>> GetRecommendedBelts(int UserID)
        {
            try
            {
                if (UserID == 0)
                {
                    throw new Exception();
                }
                List<Rates> userRates = await _context.Rates.Where(x => x.UserID == UserID)
                    .Include(x => x.User)
                    .Include(x => x.Belt)
                    .Include(x => x.Belt.BeltType)
                    .Include(x => x.Belt.User)
                    .ToListAsync();

                List<Rates> bestRatedBelt = userRates
                    .Where(x => x.Rating >= 3)
                    .ToList();
                if (bestRatedBelt.Count > 0)
                {
                    List<BeltTypes> beltType = new List<BeltTypes>();

                    foreach (var beltTypes in bestRatedBelt)
                    {
                        var beltBeltsType = await _context.Belts.Where(m => m.BeltTypeID == beltTypes.Belt.BeltTypeID)
                           .Select(s => s.BeltType)
                           .ToListAsync();

                        foreach (var x in beltBeltsType)
                        {
                            bool add = true;
                            for (int i = 0; i < beltType.Count; i++)
                            {
                                if (x.BeltName == beltType[i].BeltName)
                                {
                                    add = false;
                                }
                            }
                            if (add)
                            {
                                beltType.Add(x);
                            }
                        }
                    }


                    List<Belts> final = new List<Belts>();
                    var userBoughtBelts = await _context.Purchases.Where(k => k.UserID == UserID).Include(k => k.Order).ThenInclude(n => n.OrderItems).ToListAsync();
                    foreach (var item in beltType)
                    {
                        var beltsListBelts = await _context.Belts
                            .Where(s => s.BeltTypeID == item.BeltTypeID)
                            .Include(i => i.User)
                            .ToListAsync();

                        foreach (var belt in beltsListBelts)
                        {
                            bool add = true;
                            var ifExists = userBoughtBelts.Where(m => m.Order.OrderItems.Any(ns => ns.BeltID == belt.BeltID)).Any();
                            if (ifExists == false)
                            {
                                for (int i = 0; i < final.Count; i++)
                                {
                                    if (belt.BeltName == final[i].BeltName)
                                    {
                                        add = false;
                                    }
                                }
                                foreach (var rate in userRates)
                                {
                                    if (belt.BeltName == rate.Belt.BeltName)
                                    {
                                        add = false;
                                    }
                                }
                                if (add)
                                {
                                    final.Add(belt);
                                }
                            }
                        }
                    }

                    final = final.OrderBy(x => Guid.NewGuid()).Take(3).ToList();

                    return _mapper.Map<List<Belt>>(final);
                }
                throw new Exception();
            }
            catch (Exception ex)
            {
                return _mapper.Map<List<Belt>>(null);
            }
        }

        public async Task<List<Bag>> GetRecommendedBags(int UserID)
        {
            try
            {
                if (UserID == 0)
                {
                    throw new Exception();
                }
                List<Rates> userRates = await _context.Rates.Where(x => x.UserID == UserID)
                    .Include(x => x.User)
                    .Include(x => x.Bag)
                    .Include(x => x.Bag.BagType)
                    .Include(x => x.Bag.User)
                    .ToListAsync();

                List<Rates> bestRatedBag = userRates
                    .Where(x => x.Rating >= 3)
                    .ToList();
                if (bestRatedBag.Count > 0)
                {
                    List<BagTypes> bagType = new List<BagTypes>();

                    foreach (var bagTypes in bestRatedBag)
                    {
                        var bagBagsType = await _context.Bags.Where(m => m.BagTypeID == bagTypes.Bag.BagTypeID)
                           .Select(s => s.BagType)
                           .ToListAsync();

                        foreach (var x in bagBagsType)
                        {
                            bool add = true;
                            for (int i = 0; i < bagType.Count; i++)
                            {
                                if (x.BagName == bagType[i].BagName)
                                {
                                    add = false;
                                }
                            }
                            if (add)
                            {
                                bagType.Add(x);
                            }
                        }
                    }


                    List<Bags> final = new List<Bags>();
                    var userBoughtBags = await _context.Purchases.Where(k => k.UserID == UserID).Include(k => k.Order).ThenInclude(n => n.OrderItems).ToListAsync();
                    foreach (var item in bagType)
                    {
                        var bagsListBags = await _context.Bags
                            .Where(s => s.BagTypeID == item.BagTypeID)
                            .Include(i => i.User)
                            .ToListAsync();

                        foreach (var bag in bagsListBags)
                        {
                            bool add = true;
                            var ifExists = userBoughtBags.Where(m => m.Order.OrderItems.Any(ns => ns.BagID == bag.BagID)).Any();
                            if (ifExists == false)
                            {
                                for (int i = 0; i < final.Count; i++)
                                {
                                    if (bag.BagName == final[i].BagName)
                                    {
                                        add = false;
                                    }
                                }
                                foreach (var rate in userRates)
                                {
                                    if (bag.BagName == rate.Bag.BagName)
                                    {
                                        add = false;
                                    }
                                }
                                if (add)
                                {
                                    final.Add(bag);
                                }
                            }
                        }
                    }

                    final = final.OrderBy(x => Guid.NewGuid()).Take(3).ToList();

                    return _mapper.Map<List<Bag>>(final);
                }
                throw new Exception();
            }
            catch (Exception ex)
            {
                return _mapper.Map<List<Bag>>(null);
            }
        }
    }
}
