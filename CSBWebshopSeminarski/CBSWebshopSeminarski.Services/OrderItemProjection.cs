using CBSWebshopSeminarski.Model.Models;
using CSBWebshopSeminarski.Core.Entities;

namespace CBSWebshopSeminarski.Services
{
    public static class OrderItemProjection
    {
        public static OrderItem ToModel(OrderItems entity)
        {
            ArgumentNullException.ThrowIfNull(entity);

            return new OrderItem
            {
                OrderItemsID = entity.OrderItemID,
                OrderID = entity.OrderID,
                BagID = entity.BagID,
                BeltID = entity.BeltID,
                Quantity = entity.Quantity ?? 0,
                Price = entity.Price ?? 0m,
                Discount = entity.Discount,
                Name = entity.Bag?.BagName ?? entity.Belt?.BeltName ?? string.Empty,
                Code = entity.Bag?.Code ?? entity.Belt?.Code ?? string.Empty,
            };
        }
    }
}
