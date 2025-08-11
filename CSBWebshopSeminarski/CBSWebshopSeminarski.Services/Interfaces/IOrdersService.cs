using CBSWebshopSeminarski.Model.Models;
using CBSWebshopSeminarski.Model.Requests;

namespace CBSWebshopSeminarski.Services.Interfaces
{
    public interface IOrderService : ICRUDService<Order, OrderSearchRequest, OrderUpsertRequest, OrderUpsertRequest>
    {
        Order GetByOrderNumber(string orderNumber);
        Task<Order?> GetActiveCartByUser(int userId);
    }
}
