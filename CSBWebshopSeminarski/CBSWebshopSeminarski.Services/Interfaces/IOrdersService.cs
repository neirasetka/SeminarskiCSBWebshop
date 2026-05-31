using CBSWebshopSeminarski.Model.Models;
using CBSWebshopSeminarski.Model.Requests;
using CSBWebshopSeminarski.Core.Entities;

namespace CBSWebshopSeminarski.Services.Interfaces
{
    public interface IOrderService : ICRUDService<Order, OrderSearchRequest, OrderUpsertRequest, OrderUpsertRequest>
    {
        Order GetByOrderNumber(string orderNumber);
        Task<Order?> GetActiveCartByUser(int userId);
        Task<Order> CreateForBuyerAsync(int userId, CreateOrderRequest request);
        new Task<Order> Insert(OrderUpsertRequest request);
        Task<bool> SetPaymentStatusAsync(int orderId, PaymentStatus status, string? receiptEmail = null);
        Task<PaymentConfirmResult> ReconcilePaymentAsync(int orderId);
        Task<bool> CancelOrderAsync(int orderId, int cancelledByUserId, string? cancellationReason);
        Task<bool> CancelActiveCartAsync(int userId, string? cancellationReason = null);
        Task<PagedResult<Order>> GetOrdersForUserAsync(int userId, OrderSearchRequest? request = null, bool excludeIncompleteCarts = true);
        Task<Order?> GetFullOrderByIdAsync(int orderId);
    }
}
