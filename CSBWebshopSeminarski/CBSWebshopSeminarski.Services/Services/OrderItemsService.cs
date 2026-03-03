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
        private new readonly CocoSunBagsWebshopDbContext _context;
        private new readonly IMapper _mapper;

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
                query = query.Where(x => x.OrderID == request!.OrderID);
            }

            var list = await query.ToListAsync();
            return _mapper.Map<List<OrderItem>>(list);
        }

        public override async Task<OrderItem> Insert(OrderItemUpsertRequest request)
        {
            if (!request.BagID.HasValue && !request.BeltID.HasValue)
                throw new ArgumentException("Order item must have either BagID or BeltID.");

            // Ako klijent pošalje cijenu 0, dohvati pravu cijenu iz artikla (Bag ili Belt)
            if (request.Price <= 0)
            {
                if (request.BagID.HasValue)
                {
                    var bag = await _context.Bags.FindAsync(request.BagID.Value);
                    if (bag != null)
                        request.Price = bag.Price;
                }
                else if (request.BeltID.HasValue)
                {
                    var belt = await _context.Belts.FindAsync(request.BeltID.Value);
                    if (belt != null)
                        request.Price = belt.Price;
                }
            }

            var entity = _mapper.Map<OrderItems>(request);

            _context.Set<OrderItems>().Add(entity);
            await _context.SaveChangesAsync();
            await RecalculateOrderTotal(entity.OrderID);
            return _mapper.Map<OrderItem>(entity);
        }

        public override async Task<OrderItem> Update(int ID, OrderItemUpsertRequest request)
        {
            var entity = _context.Set<OrderItems>().Find(ID);
            if (entity == null)
                throw new ArgumentException($"Order item with ID {ID} not found.");
            _context.Set<OrderItems>().Attach(entity);
            _context.Set<OrderItems>().Update(entity);

            _mapper.Map(request, entity);

            await _context.SaveChangesAsync();
            await RecalculateOrderTotal(entity.OrderID);
            return _mapper.Map<OrderItem>(entity);
        }

        public override async Task<bool> Delete(int ID)
        {
            var entity = await _context.OrderItems.Where(oi => oi.OrderItemID == ID).FirstOrDefaultAsync();
            if (entity == null) return false;
            var orderId = entity.OrderID;
            _context.OrderItems.Remove(entity);
            await _context.SaveChangesAsync();
            await RecalculateOrderTotal(orderId);
            return true;
        }

        private async Task RecalculateOrderTotal(int orderId)
        {
            var order = await _context.Orders.Include(o => o.OrderItems).FirstOrDefaultAsync(o => o.OrderID == orderId);
            if (order == null) return;
            decimal total = 0m;
            foreach (var item in order.OrderItems)
            {
                var price = (decimal)(item.Price ?? 0f);
                var qty = item.Quantity ?? 1;
                var line = price * qty;
                if (item.Discount.HasValue) line -= item.Discount.Value;
                total += line;
            }
            order.Price = (float)total;
            await _context.SaveChangesAsync();
        }
    }
}
