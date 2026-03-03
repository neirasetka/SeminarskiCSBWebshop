using CBSWebshopSeminarski.Model.Models;
using CBSWebshopSeminarski.Model.Requests;
using CSBWebshopSeminarski.Core.Entities;

namespace CBSWebshopSeminarski.Services.Interfaces
{
    public interface IOrderService : ICRUDService<Order, OrderSearchRequest, OrderUpsertRequest, OrderUpsertRequest>
    {
        Order GetByOrderNumber(string orderNumber);
        Task<Order?> GetActiveCartByUser(int userId);
        Task<Order> Insert(OrderUpsertRequest request);
        Task<bool> SetPaymentStatusAsync(int orderId, PaymentStatus status);
        Task<bool> CancelActiveCartAsync(int userId);
    }
}
