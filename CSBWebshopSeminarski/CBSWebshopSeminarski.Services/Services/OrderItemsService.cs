using AutoMapper;
using CBSWebshopSeminarski.Model.Models;
using CBSWebshopSeminarski.Model.Requests;
using CSBWebshopSeminarski.Core.Entities;
using CSBWebshopSeminarski.Database;
using Microsoft.EntityFrameworkCore;

namespace CBSWebshopSeminarski.Services.Services
{
    public class OrderItemsService : CRUDService<OrderItem, OrderItemSearchRequest, OrderItems, OrderItemUpsertRequest, OrderItemUpsertRequest>
    {
        private readonly CocoSunBagsWebshopDbContext _context;
        private readonly IMapper _mapper;

        public OrderItemsService(CocoSunBagsWebshopDbContext context, IMapper mapper) : base(context, mapper)
        {
            _context = context;
            _mapper = mapper;
        }

        public override async Task<List<OrderItem>> Get(OrderItemSearchRequest request)
        {
            var query = _context.OrderItems.
           Include(z => z.Belt).Include(c => c.Bag)
           .AsQueryable();
            if (request?.OrderID != 0)
            {
                query = query.Where(x => x.OrderID == request.OrderID);
            }

            var list = query.ToList();
            return _mapper.Map<List<OrderItem>>(list);
        }

        public override async Task<OrderItem> Insert(OrderItemUpsertRequest request)
        {
            var entity = _mapper.Map<OrderItems>(request);

            _context.Set<OrderItems>().Add(entity);
            await _context.SaveChangesAsync();

            return _mapper.Map<OrderItem>(entity);
        }

        public override async Task<OrderItem> Update(int ID, OrderItemUpsertRequest request)
        {

            var entity = _context.Set<OrderItems>().Find(ID);
            _context.Set<OrderItems>().Attach(entity);
            _context.Set<OrderItems>().Update(entity);

            _mapper.Map(request, entity);

            await _context.SaveChangesAsync();

            return _mapper.Map<OrderItem>(entity);
        }

        public override async Task<bool> Delete(int ID)
        {
            var orderItem = await _context.OrderItems.Where(c => c.OrderID == ID).FirstOrDefaultAsync();

            if (orderItem != null)
            {
                var orders = await _context.OrderItems.Where(i => i.OrderID == ID).ToListAsync();
                if (orders != null)
                    _context.OrderItems.RemoveRange(orders);
                return true;
            }
            return false;
        }
    }
}
