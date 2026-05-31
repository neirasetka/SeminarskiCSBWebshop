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
        private new readonly CocoSunBagsWebshopDbContext _context;
        private new readonly IMapper _mapper;
        public PurchasesService(CocoSunBagsWebshopDbContext context, IMapper mapper) : base(context, mapper)
        {
            _context = context;
            _mapper = mapper;
        }

        public override async Task<PagedResult<Purchase>> Get(PurchaseSearchRequest request)
        {
            var query = _context.Purchases.AsQueryable();

            if (request.UserID != 0)
            {
                query = query.Where(i => i.UserID == request.UserID);
            }
            if (request.OrderID != 0)
            {
                query = query.Where(i => i.OrderID == request.OrderID);
            }
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
                query = query.Where(p => _context.OrderItems.Any(oi =>
                    oi.OrderID == p.OrderID && oi.BagID == request.BagID));
            }
            if (request.BeltID != 0)
            {
                query = query.Where(p => _context.OrderItems.Any(oi =>
                    oi.OrderID == p.OrderID && oi.BeltID == request.BeltID));
            }

            query = query.OrderByDescending(i => i.PurchaseDate);

            return await ToPagedResultAsync(query, request);
        }
    }
}
