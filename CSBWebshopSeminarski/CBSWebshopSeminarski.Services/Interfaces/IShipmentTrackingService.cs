using CBSWebshopSeminarski.Model.Models;
using CBSWebshopSeminarski.Model.Requests;

namespace CBSWebshopSeminarski.Services.Interfaces
{
    public interface IShipmentTrackingService
    {
        Task<ShippingInfo> SetTrackingInfoAsync(int orderId, SetShippingInfoRequest request);
        Task<ShippingInfo> GetShippingInfoAsync(int orderId);
        Task<ShippingInfo> UpdateStatusAsync(int orderId, UpdateShippingStatusRequest request);
        Task<bool> RefreshFromCarrierAsync(int orderId);
        Task HandleCarrierWebhookAsync(string carrierCode, CarrierWebhookPayload payload);
    }
}
