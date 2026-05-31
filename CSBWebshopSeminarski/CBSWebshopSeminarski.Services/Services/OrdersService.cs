using AutoMapper;
using CBSWebshopSeminarski.Model.Models;
using CBSWebshopSeminarski.Model.Requests;
using CBSWebshopSeminarski.Services;
using CBSWebshopSeminarski.Services.Interfaces;
using CBSWebshopSeminarski.Services.StateMachines;
using CSBWebshopSeminarski.Core.Entities;
using CSBWebshopSeminarski.Database;
using Microsoft.EntityFrameworkCore;
using ShippingStatusEntity = CSBWebshopSeminarski.Core.Entities.ShippingStatus;

using CBSWebshopSeminarski.Services.Exceptions;

namespace CBSWebshopSeminarski.Services.Services
{
    public class OrdersService : CRUDService<Order, OrderSearchRequest, Orders, OrderUpsertRequest, OrderUpsertRequest>, IOrderService
    {
        private new readonly CocoSunBagsWebshopDbContext _context;
        private new readonly IMapper _mapper;
        private readonly IPaymentsService _paymentsService;
        private readonly IInAppNotificationService _inAppNotifications;

        public OrdersService(
            CocoSunBagsWebshopDbContext context,
            IMapper mapper,
            IPaymentsService paymentsService,
            IInAppNotificationService inAppNotifications) : base(context, mapper)
        {
            _context = context;
            _mapper = mapper;
            _paymentsService = paymentsService;
            _inAppNotifications = inAppNotifications;
        }

        public override async Task<PagedResult<Order>> Get(OrderSearchRequest request)
        {
            var query = _context.Orders
                .Include(o => o.User)
                .AsQueryable();

            if (!string.IsNullOrWhiteSpace(request?.OrderNumber))
            {
                query = query.Where(x => x.OrderNumber.StartsWith(request.OrderNumber));
            }

            query = query.OrderByDescending(x => x.Date);
            return await ToPagedResultAsync(query, request);
        }

        public async Task<PagedResult<Order>> GetOrdersForUserAsync(
            int userId,
            OrderSearchRequest? request = null,
            bool excludeIncompleteCarts = true)
        {
            request ??= new OrderSearchRequest();
            var query = _context.Orders
                .Include(o => o.User)
                .Where(o => o.UserID == userId);

            if (excludeIncompleteCarts)
            {
                query = query.Where(o =>
                    o.PaymentStatus != PaymentStatus.Pending
                    || (o.ShippingStatus != ShippingStatusEntity.Pending
                        && o.ShippingStatus != ShippingStatusEntity.Cancelled));
            }

            query = query.OrderByDescending(o => o.Date);

            return await ToPagedResultAsync(query, request);
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

        public async Task<Order> CreateForBuyerAsync(int userId, CreateOrderRequest request)
        {
            var entity = new Orders
            {
                UserID = userId,
                Price = 0,
                OrderNumber = string.IsNullOrWhiteSpace(request.OrderNumber)
                    ? GenerateOrderNumber()
                    : request.OrderNumber.Trim(),
                Date = request.Date ?? DateTime.UtcNow,
                PaymentStatus = PaymentStatus.Pending,
                ShippingStatus = ShippingStatusEntity.Pending
            };

            _context.Set<Orders>().Add(entity);
            await _context.SaveChangesAsync();
            return _mapper.Map<Order>(entity);
        }

        public override async Task<Order> Insert(OrderUpsertRequest request)
        {
            var entity = _mapper.Map<Orders>(request);
            entity.Price = 0;

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

            return _mapper.Map<Order>(entity);
        }

        public override async Task<Order> Update(int ID, OrderUpsertRequest request)
        {
            var entity = _context.Set<Orders>().Find(ID);
            if (entity == null)
                throw new NotFoundException($"Order with ID {ID} not found.");
            _context.Set<Orders>().Attach(entity);
            _context.Set<Orders>().Update(entity);

            _mapper.Map(request, entity);

            await _context.SaveChangesAsync();

            return _mapper.Map<Order>(entity);
        }

        public override async Task<bool> Delete(int ID)
        {
            throw new NotSupportedException(
                "Orders are not physically deleted. Use CancelOrderAsync or the cancel endpoint.");
        }

        public async Task<bool> CancelOrderAsync(int orderId, int cancelledByUserId, string? cancellationReason)
        {
            var order = await _context.Orders.FirstOrDefaultAsync(o => o.OrderID == orderId);
            if (order == null)
                return false;

            return await ApplyCancellationAsync(order, cancelledByUserId, cancellationReason, abandonedCart: false);
        }

        public Order GetByOrderNumber(string orderNumber)
        {
            var entity = _context.Orders.Where(n => n.OrderNumber == orderNumber).FirstOrDefault();

            if (entity == null)
            {
                throw new NotFoundException("Order not found");
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
            if (status == PaymentStatus.Paid)
            {
                throw new BusinessException(
                    "Paid status cannot be set manually. Use POST /api/Orders/{orderId}/reconcile-payment to verify Stripe payment.");
            }

            var order = await _context.Orders.FirstOrDefaultAsync(o => o.OrderID == orderId);
            if (order == null) return false;
            StateMachines.OrderStateMachine.ValidatePaymentTransition(order.PaymentStatus, status);
            order.PaymentStatus = status;
            await _context.SaveChangesAsync();
            return true;
        }

        public Task<PaymentConfirmResult> ReconcilePaymentAsync(int orderId) =>
            _paymentsService.ReconcileOrderPaymentAsync(orderId);

        public async Task<bool> CancelActiveCartAsync(int userId, string? cancellationReason = null)
        {
            var order = await GetActiveCartByUser(userId);
            if (order == null) return false;
            var entity = await _context.Orders
                .FirstOrDefaultAsync(o => o.OrderID == order.OrderID);
            if (entity == null) return false;

            return await ApplyCancellationAsync(
                entity,
                userId,
                cancellationReason ?? "Buyer cancelled active cart",
                abandonedCart: true);
        }

        private async Task<bool> ApplyCancellationAsync(
            Orders order,
            int cancelledByUserId,
            string? cancellationReason,
            bool abandonedCart)
        {
            if (order.ShippingStatus == ShippingStatusEntity.Cancelled)
                return false;

            StateMachines.ShippingStateMachine.ValidateTransition(
                order.ShippingStatus, ShippingStatusEntity.Cancelled);

            order.ShippingStatus = ShippingStatusEntity.Cancelled;
            order.CancelledAt = DateTime.UtcNow;
            order.CancelledByUserId = cancelledByUserId;
            order.CancellationReason = cancellationReason;
            order.LastStatusUpdate = DateTime.UtcNow;

            if (!abandonedCart
                && order.PaymentStatus == PaymentStatus.Pending
                && StateMachines.OrderStateMachine.CanTransitionPayment(order.PaymentStatus, PaymentStatus.Failed))
            {
                order.PaymentStatus = PaymentStatus.Failed;
            }

            _inAppNotifications.StageCreate(
                order.UserID,
                InAppNotificationTypes.OrderCancelled,
                "Narudžba otkazana",
                abandonedCart
                    ? $"Aktivna korpa (narudžba #{order.OrderNumber}) je otkazana."
                    : $"Narudžba #{order.OrderNumber} je otkazana.",
                order.OrderID);

            await _context.SaveChangesAsync();

            return true;
        }
    }
}
