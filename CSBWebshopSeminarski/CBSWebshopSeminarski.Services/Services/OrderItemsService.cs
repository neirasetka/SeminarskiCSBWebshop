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

        public override async Task<PagedResult<OrderItem>> Get(OrderItemSearchRequest request)
        {
            var query = _context.OrderItems
                .Include(z => z.Belt).Include(c => c.Bag)
                .AsQueryable();
            if (request?.OrderID != 0)
            {
                query = query.Where(x => x.OrderID == request!.OrderID);
            }

            return await ToPagedResultAsync(query, request);
        }

        public override async Task<OrderItem> Insert(OrderItemUpsertRequest request)
        {
            if (!request.BagID.HasValue && !request.BeltID.HasValue)
                throw new ArgumentException("Order item must have either BagID or BeltID.");
            if (request.BagID.HasValue && request.BagID.Value < 1)
                throw new ArgumentException("BagID must be a valid bag identifier.");
            if (request.BeltID.HasValue && request.BeltID.Value < 1)
                throw new ArgumentException("BeltID must be a valid belt identifier.");

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

            if (request.Price <= 0)
                throw new ArgumentException("Cijena stavke mora biti veća od 0. Osvježite katalog ili provjerite artikal u administraciji.");

            var entity = _mapper.Map<OrderItems>(request);

            var order = await _context.Orders
                .Include(o => o.OrderItems)
                .FirstOrDefaultAsync(o => o.OrderID == entity.OrderID)
                ?? throw new ArgumentException($"Order with ID {entity.OrderID} not found.");

            order.OrderItems.Add(entity);
            ApplyOrderTotal(order);
            await SaveChangesWithOrderItemsNullableRepairAsync();
            // Ponovno učitaj stavku s Bag/Belt radi stabilnog mapiranja na OrderItem (izbjegava iznimke na pratnom entitetu).
            var insertedId = entity.OrderItemID;
            var forReturn = await _context.OrderItems
                .AsNoTracking()
                .Include(oi => oi.Bag)
                .Include(oi => oi.Belt)
                .FirstOrDefaultAsync(oi => oi.OrderItemID == insertedId);
            return _mapper.Map<OrderItem>(forReturn ?? entity);
        }

        public override async Task<OrderItem> Update(int ID, OrderItemUpsertRequest request)
        {
            var entity = _context.Set<OrderItems>().Find(ID);
            if (entity == null)
                throw new ArgumentException($"Order item with ID {ID} not found.");
            _context.Set<OrderItems>().Attach(entity);
            _context.Set<OrderItems>().Update(entity);

            _mapper.Map(request, entity);

            var order = await _context.Orders
                .Include(o => o.OrderItems)
                .FirstOrDefaultAsync(o => o.OrderID == entity.OrderID);
            if (order != null)
                ApplyOrderTotal(order);

            await SaveChangesWithOrderItemsNullableRepairAsync();
            return _mapper.Map<OrderItem>(entity);
        }

        public override async Task<bool> Delete(int ID)
        {
            var entity = await _context.OrderItems.Where(oi => oi.OrderItemID == ID).FirstOrDefaultAsync();
            if (entity == null) return false;

            var order = await _context.Orders
                .Include(o => o.OrderItems)
                .FirstOrDefaultAsync(o => o.OrderID == entity.OrderID);

            _context.OrderItems.Remove(entity);
            if (order != null)
                ApplyOrderTotal(order);

            await SaveChangesWithOrderItemsNullableRepairAsync();
            return true;
        }

        /// <summary>
        /// Legacy databases may still have NOT NULL on <c>OrderItems.BagID</c>/<c>BeltID</c> if startup
        /// repair did not run (e.g. seeding failed first). Repair once and retry <see cref="DbContext.SaveChangesAsync"/>.
        /// </summary>
        private async Task SaveChangesWithOrderItemsNullableRepairAsync()
        {
            try
            {
                await _context.SaveChangesAsync();
            }
            catch (DbUpdateException ex) when (IsOrderItemsBagBeltNullConstraintError(ex))
            {
                await _context.Database.ExecuteSqlRawAsync(OrderItemsSchemaCompatibility.EnsureOrderItemsBagOrBeltColumnsNullableSql);
                await _context.SaveChangesAsync();
            }
        }

        private static bool IsOrderItemsBagBeltNullConstraintError(DbUpdateException ex)
        {
            for (var e = (Exception?)ex; e != null; e = e.InnerException)
            {
                var msg = e.Message;
                if (!msg.Contains("NULL", StringComparison.OrdinalIgnoreCase))
                    continue;
                if (msg.Contains("Cannot insert the value NULL", StringComparison.OrdinalIgnoreCase)
                    || msg.Contains("Cannot update the value NULL", StringComparison.OrdinalIgnoreCase))
                {
                    return msg.Contains("BagID", StringComparison.OrdinalIgnoreCase)
                           || msg.Contains("BeltID", StringComparison.OrdinalIgnoreCase);
                }
            }

            return false;
        }

        private void ApplyOrderTotal(Orders order)
        {
            decimal total = 0m;

            foreach (var item in order.OrderItems)
            {
                if (_context.Entry(item).State == EntityState.Deleted)
                    continue;

                var price = item.Price ?? 0m;
                var qty = item.Quantity ?? 1;

                var line = price * qty;

                if (item.Discount.HasValue)
                    line -= item.Discount.Value;

                total += line;
            }

            order.Price = total;
        }
    }
}
