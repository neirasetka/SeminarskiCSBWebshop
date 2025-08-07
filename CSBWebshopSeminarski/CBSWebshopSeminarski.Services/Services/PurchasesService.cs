using AutoMapper;
using CBSWebshopSeminarski.Model.Models;
using CBSWebshopSeminarski.Model.Requests;
using CSBWebshopSeminarski.Core.Entities;
using CSBWebshopSeminarski.Database;
using Microsoft.EntityFrameworkCore;

namespace CBSWebshopSeminarski.Services.Services
{
    public class PurchasesService : CRUDService<Purchase, PurchaseSearchRequest, Purchases, PurchaseUpsertRequest, PurchaseUpsertRequest>
    {
        private readonly CocoSunBagsWebshopDbContext _context;
        private readonly IMapper _mapper;
        public PurchasesService(CocoSunBagsWebshopDbContext context, IMapper mapper) : base(context, mapper)
        {
            _context = context;
            _mapper = mapper;
        }

        public override async Task<List<Purchase>> Get(PurchaseSearchRequest request)
        {
            var query = _context.Purchases.AsQueryable();

            if (request.From != null)
            {
                query = query.Where(i => i.PurchaseDate >= request.From);
            }
            if (request.To != null)
            {
                query = query.Where(i => i.PurchaseDate <= request.To);
            }
            if (request.BagID != 0)
            {
                query = query.Where(i => i.OrderID == request.OrderID);
            }
            if (request.BeltID != 0)
            {
                query = query.Where(i => i.OrderID == request.OrderID);
            }

            var list = await query.ToListAsync();

            return _mapper.Map<List<Purchase>>(query);
        }
    }
}
