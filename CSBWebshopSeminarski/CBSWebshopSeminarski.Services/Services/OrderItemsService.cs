using AutoMapper;
using CBSWebshopSeminarski.Model.Models;
using CBSWebshopSeminarski.Model.Requests;
using CBSWebshopSeminarski.Services;
using CBSWebshopSeminarski.Services.Interfaces;
using CSBWebshopSeminarski.Core.Entities;
using CSBWebshopSeminarski.Database;
using ShippingStatusEntity = CSBWebshopSeminarski.Core.Entities.ShippingStatus;
using Microsoft.EntityFrameworkCore;

using CBSWebshopSeminarski.Services.Exceptions;

namespace CBSWebshopSeminarski.Services.Services
{
    public class OrderItemsService : CRUDService<OrderItem, OrderItemSearchRequest, OrderItems, OrderItemUpsertRequest, OrderItemUpsertRequest>
    {
        private new readonly CocoSunBagsWebshopDbContext _context;
        private new readonly IMapper _mapper;
        private readonly IPaymentsService _paymentsService;

        public OrderItemsService(
            CocoSunBagsWebshopDbContext context,
            IMapper mapper,
            IPaymentsService paymentsService) : base(context, mapper)
        {
            _context = context;
            _mapper = mapper;
            _paymentsService = paymentsService;
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
            return await _context.ExecuteInTransactionAsync(async () =>
            {
                await PrepareCartMutationAsync(request.OrderID);
                await ResolveCatalogPriceAsync(request);

                var entity = _mapper.Map<OrderItems>(request);

                var order = await _context.Orders
                    .Include(o => o.OrderItems)
                    .FirstOrDefaultAsync(o => o.OrderID == entity.OrderID)
                    ?? throw new NotFoundException($"Order with ID {entity.OrderID} not found.");

                order.OrderItems.Add(entity);
                ApplyOrderTotal(order);
                await SaveChangesWithOrderItemsNullableRepairAsync();
                var insertedId = entity.OrderItemID;
                var forReturn = await _context.OrderItems
                    .AsNoTracking()
                    .Include(oi => oi.Bag)
                    .Include(oi => oi.Belt)
                    .FirstOrDefaultAsync(oi => oi.OrderItemID == insertedId);
                return _mapper.Map<OrderItem>(forReturn ?? entity);
            });
        }

        public override async Task<OrderItem> Update(int ID, OrderItemUpsertRequest request)
        {
            return await _context.ExecuteInTransactionAsync(async () =>
            {
                var entity = _context.Set<OrderItems>().Find(ID);
                if (entity == null)
                    throw new NotFoundException($"Order item with ID {ID} not found.");

                await PrepareCartMutationAsync(entity.OrderID);
                await ResolveCatalogPriceAsync(request);

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
            });
        }

        public override async Task<bool> Delete(int ID)
        {
            return await _context.ExecuteInTransactionAsync(async () =>
            {
                var entity = await _context.OrderItems.Where(oi => oi.OrderItemID == ID).FirstOrDefaultAsync();
                if (entity == null) return false;

                await PrepareCartMutationAsync(entity.OrderID);

                var order = await _context.Orders
                    .Include(o => o.OrderItems)
                    .FirstOrDefaultAsync(o => o.OrderID == entity.OrderID);

                _context.OrderItems.Remove(entity);
                if (order != null)
                    ApplyOrderTotal(order);

                await SaveChangesWithOrderItemsNullableRepairAsync();
                return true;
            });
        }

        private async Task PrepareCartMutationAsync(int orderId)
        {
            var order = await _context.Orders.FindAsync(orderId)
                ?? throw new NotFoundException($"Order with ID {orderId} not found.");

            if (order.ShippingStatus == ShippingStatusEntity.Cancelled)
                throw new BusinessException("Otkazana narudžba se ne može mijenjati.");

            if (order.PaymentStatus == PaymentStatus.Paid)
                throw new BusinessException("Plaćena narudžba se ne može mijenjati.");

            if (order.PaymentStatus != PaymentStatus.Pending)
                throw new BusinessException("Narudžba se ne može mijenjati u trenutnom statusu plaćanja.");

            await _paymentsService.InvalidateActiveCheckoutAsync(orderId);
        }

        private async Task ResolveCatalogPriceAsync(OrderItemUpsertRequest request)
        {
            if (request.Price.HasValue && request.Price.Value > 0)
                return;

            if (request.BagID.HasValue)
            {
                var bag = await _context.Bags.FindAsync(request.BagID.Value)
                    ?? throw new NotFoundException($"Bag with ID {request.BagID.Value} not found.");
                request.Price = bag.Price;
            }
            else if (request.BeltID.HasValue)
            {
                var belt = await _context.Belts.FindAsync(request.BeltID.Value)
                    ?? throw new NotFoundException($"Belt with ID {request.BeltID.Value} not found.");
                request.Price = belt.Price;
            }
            else
            {
                throw new ValidationException("Order item must reference a bag or a belt.");
            }

            if (request.Price.Value <= 0)
            {
                throw new ValidationException(
                    "Cijena artikla u katalogu mora biti veća od 0. Provjerite artikal u administraciji.");
            }
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

                if (item.Discount.HasValue && item.Discount.Value > 0)
                    line *= 1 - item.Discount.Value / 100m;

                total += line;
            }

            order.Price = total;
        }
    }
}
