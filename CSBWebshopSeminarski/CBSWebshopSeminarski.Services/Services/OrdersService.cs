using AutoMapper;
using CBSWebshopSeminarski.Model.Models;
using CBSWebshopSeminarski.Model.Requests;
using CBSWebshopSeminarski.Services.Interfaces;
using CSBWebshopSeminarski.Core.Entities;
using CSBWebshopSeminarski.Database;
using Microsoft.EntityFrameworkCore;
using ShippingStatusEntity = CSBWebshopSeminarski.Core.Entities.ShippingStatus;

namespace CBSWebshopSeminarski.Services.Services
{
    public class OrdersService : CRUDService<Order, OrderSearchRequest, Orders, OrderUpsertRequest, OrderUpsertRequest>, IOrderService
    {
        private new readonly CocoSunBagsWebshopDbContext _context;
        private new readonly IMapper _mapper;
        private readonly IEventPublisher _eventPublisher;
        private readonly IPaymentsService _paymentsService;

        public OrdersService(
            CocoSunBagsWebshopDbContext context,
            IMapper mapper,
            IEventPublisher eventPublisher,
            IPaymentsService paymentsService) : base(context, mapper)
        {
            _context = context;
            _mapper = mapper;
            _eventPublisher = eventPublisher;
            _paymentsService = paymentsService;
        }

        public override async Task<List<Order>> Get(OrderSearchRequest request)
        {
            var query = _context.Orders
                .Include(o => o.User)
                .AsQueryable();

            if (!string.IsNullOrWhiteSpace(request?.OrderNumber))
            {
                query = query.Where(x => x.OrderNumber.StartsWith(request.OrderNumber));
            }

            var list = await query
                .OrderByDescending(x => x.Date)
                .ToListAsync();

            return _mapper.Map<List<Order>>(list);
        }

        public async Task<List<Order>> GetOrdersForUserAsync(int userId)
        {
            var list = await _context.Orders
                .Include(o => o.User)
                .Where(o => o.UserID == userId)
                .OrderByDescending(o => o.Date)
                .ToListAsync();

            return _mapper.Map<List<Order>>(list);
        }

        public async Task<Order?> GetFullOrderByIdAsync(int orderId)
        {
            var entity = await _context.Orders
                .Include(o => o.User)
                .Include(o => o.OrderItems)
                    .ThenInclude(oi => oi.Bag)
                .Include(o => o.OrderItems)
                    .ThenInclude(oi => oi.Belt)
                .FirstOrDefaultAsync(o => o.OrderID == orderId);

            return entity == null ? null : _mapper.Map<Order>(entity);
        }

        public override async Task<Order> Insert(OrderUpsertRequest request)
        {
            var entity = _mapper.Map<Orders>(request);

            if (string.IsNullOrWhiteSpace(entity.OrderNumber))
            {
                entity.OrderNumber = GenerateOrderNumber();
            }
            if (entity.Date == default)
            {
                entity.Date = DateTime.UtcNow;
            }

            _context.Set<Orders>().Add(entity);
            await _context.SaveChangesAsync();

            var result = _mapper.Map<Order>(entity);

            try
            {
                var user = await _context.Users.FirstOrDefaultAsync(u => u.UserID == entity.UserID);
                var evt = new CBSWebshopSeminarski.Model.Events.OrderCreatedEvent
                {
                    OrderID = entity.OrderID,
                    OrderNumber = entity.OrderNumber,
                    UserID = entity.UserID,
                    UserEmail = user?.Email,
                    Amount = (decimal)entity.Price,
                    CreatedAtUtc = DateTime.UtcNow
                };
                await _eventPublisher.PublishAsync("orders.created", evt);
            }
            catch
            {
            }

            return result;
        }

        public override async Task<Order> Update(int ID, OrderUpsertRequest request)
        {
            var entity = _context.Set<Orders>().Find(ID);
            if (entity == null)
                throw new ArgumentException($"Order with ID {ID} not found.");
            _context.Set<Orders>().Attach(entity);
            _context.Set<Orders>().Update(entity);

            _mapper.Map(request, entity);

            await _context.SaveChangesAsync();

            return _mapper.Map<Order>(entity);
        }

        public override async Task<bool> Delete(int ID)
        {
            var orders = await _context.Orders.Where(c => c.OrderID == ID).FirstOrDefaultAsync();

            if (orders != null)
            {
                await _context.SaveChangesAsync();

                _context.Orders.Remove(orders);
                await _context.SaveChangesAsync();

                return true;
            }
            return false;
        }

        public Order GetByOrderNumber(string orderNumber)
        {
            var entity = _context.Orders.Where(n => n.OrderNumber.Contains(orderNumber)).FirstOrDefault();

            if (entity == null)
            {
                throw new Exception("Order not found");
            }
            return _mapper.Map<Order>(entity);
        }

        public async Task<Order?> GetActiveCartByUser(int userId)
        {
            var entity = await _context.Orders
                .Include(o => o.OrderItems)
                    .ThenInclude(oi => oi.Bag)
                .Include(o => o.OrderItems)
                    .ThenInclude(oi => oi.Belt)
                .Where(o => o.UserID == userId
                    && o.PaymentStatus == PaymentStatus.Pending
                    && o.ShippingStatus == ShippingStatusEntity.Pending)
                .OrderByDescending(o => o.Date)
                .FirstOrDefaultAsync();

            if (entity == null)
            {
                return null;
            }

            return _mapper.Map<Order>(entity);
        }

        private static string GenerateOrderNumber()
        {
            var now = DateTime.UtcNow;
            var rand = Random.Shared.Next(10000, 99999);
            return $"ORD-{now:yyyyMMdd}-{rand}";
        }

        public async Task<bool> SetPaymentStatusAsync(int orderId, PaymentStatus status, string? receiptEmail = null)
        {
            var order = await _context.Orders.FirstOrDefaultAsync(o => o.OrderID == orderId);
            if (order == null) return false;
            order.PaymentStatus = status;
            await _context.SaveChangesAsync();
            if (status == PaymentStatus.Paid)
            {
                await _paymentsService.SendPaymentConfirmationIfNotSentYetAsync(orderId, receiptEmail);
            }
            return true;
        }

        public async Task<bool> CancelActiveCartAsync(int userId)
        {
            var order = await GetActiveCartByUser(userId);
            if (order == null) return false;
            var entity = await _context.Orders
                .Include(o => o.OrderItems)
                .FirstOrDefaultAsync(o => o.OrderID == order.OrderID);
            if (entity == null) return false;
            _context.OrderItems.RemoveRange(entity.OrderItems);
            await _context.SaveChangesAsync();
            _context.Orders.Remove(entity);
            await _context.SaveChangesAsync();
            return true;
        }
    }
}
