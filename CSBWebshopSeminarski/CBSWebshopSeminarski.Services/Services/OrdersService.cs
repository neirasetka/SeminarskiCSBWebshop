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
        private readonly CocoSunBagsWebshopDbContext _context;
        private readonly IMapper _mapper;
        private readonly IEventPublisher _eventPublisher;

        public OrdersService(CocoSunBagsWebshopDbContext context, IMapper mapper, IEventPublisher eventPublisher) : base(context, mapper)
        {
            _context = context;
            _mapper = mapper;
            _eventPublisher = eventPublisher;
        }

        public override async Task<List<Order>> Get(OrderSearchRequest request)
        {
            var query = _context.Orders.
               Include(z => z.User)
               .AsQueryable();

            if (!string.IsNullOrWhiteSpace(request?.OrderNumber))
            {
                query = query.Where(x => x.OrderNumber.StartsWith(request.OrderNumber));
            }

            var list = query.ToList();

            List<Orders> result = new List<Orders>();

            foreach (var item in list)
            {
                Orders newList = new Orders();

                newList.OrderNumber = item.OrderNumber;
                newList.Date = item.Date;
                newList.Price = item.Price;
                newList.UserID = item.User.UserID;
                newList.OrderID = item.OrderID;

                result.Add(newList);
            }

            return _mapper.Map<List<Order>>(result);
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

        public async Task<bool> SetPaymentStatusAsync(int orderId, PaymentStatus status)
        {
            var order = await _context.Orders.FirstOrDefaultAsync(o => o.OrderID == orderId);
            if (order == null) return false;
            order.PaymentStatus = status;
            await _context.SaveChangesAsync();
            return true;
        }
    }
}
