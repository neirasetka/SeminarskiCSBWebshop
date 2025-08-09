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
    public class ShipmentTrackingService : IShipmentTrackingService
    {
        private readonly CocoSunBagsWebshopDbContext _dbContext;
        private readonly IMapper _mapper;

        public ShipmentTrackingService(CocoSunBagsWebshopDbContext dbContext, IMapper mapper)
        {
            _dbContext = dbContext;
            _mapper = mapper;
        }

        public async Task<ShippingInfo> SetTrackingInfoAsync(int orderId, SetShippingInfoRequest request)
        {
            var order = await _dbContext.Orders.Include(o => o.TrackingEvents).FirstOrDefaultAsync(o => o.OrderID == orderId)
                ?? throw new KeyNotFoundException($"Order {orderId} not found");

            order.CarrierCode = request.CarrierCode;
            order.TrackingNumber = request.TrackingNumber;
            order.EstimatedDeliveryDate = request.EstimatedDeliveryDate;

            if (order.ShippingStatus == ShippingStatusEntity.Pending)
            {
                order.ShippingStatus = ShippingStatusEntity.Shipped;
                order.LastStatusUpdate = DateTime.UtcNow;

                _dbContext.TrackingEvents.Add(new TrackingEvents
                {
                    OrderID = order.OrderID,
                    Status = ShippingStatusEntity.Shipped,
                    Message = "Shipment created",
                    OccurredAt = DateTime.UtcNow,
                    Source = "Manual"
                });
            }

            await _dbContext.SaveChangesAsync();
            return await GetShippingInfoAsync(orderId);
        }

        public async Task<ShippingInfo> GetShippingInfoAsync(int orderId)
        {
            var order = await _dbContext.Orders
                .Include(o => o.TrackingEvents)
                .FirstOrDefaultAsync(o => o.OrderID == orderId)
                ?? throw new KeyNotFoundException($"Order {orderId} not found");

            var result = _mapper.Map<ShippingInfo>(order);
            result.TrackingEvents = order.TrackingEvents
                .OrderBy(e => e.OccurredAt)
                .Select(e => _mapper.Map<TrackingEvent>(e))
                .ToList();
            return result;
        }

        public async Task<ShippingInfo> UpdateStatusAsync(int orderId, UpdateShippingStatusRequest request)
        {
            var order = await _dbContext.Orders.Include(o => o.TrackingEvents).FirstOrDefaultAsync(o => o.OrderID == orderId)
                ?? throw new KeyNotFoundException($"Order {orderId} not found");

            order.ShippingStatus = (ShippingStatusEntity)request.Status;
            order.LastStatusUpdate = DateTime.UtcNow;

            _dbContext.TrackingEvents.Add(new TrackingEvents
            {
                OrderID = order.OrderID,
                Status = (ShippingStatusEntity)request.Status,
                Message = request.Message,
                Location = request.Location,
                OccurredAt = request.OccurredAt ?? DateTime.UtcNow,
                Source = "Manual"
            });

            await _dbContext.SaveChangesAsync();
            return await GetShippingInfoAsync(orderId);
        }

        public async Task<bool> RefreshFromCarrierAsync(int orderId)
        {
            // Placeholder: here you would call the carrier API via injected ICarrierClient
            // For now, this method is a no-op and returns false to indicate no change
            var orderExists = await _dbContext.Orders.AnyAsync(o => o.OrderID == orderId);
            if (!orderExists) throw new KeyNotFoundException($"Order {orderId} not found");
            return false;
        }

        public async Task HandleCarrierWebhookAsync(string carrierCode, CarrierWebhookPayload payload)
        {
            var order = await _dbContext.Orders
                .Include(o => o.TrackingEvents)
                .FirstOrDefaultAsync(o => o.OrderID == payload.OrderID ||
                                           (!string.IsNullOrEmpty(payload.TrackingNumber) && o.TrackingNumber == payload.TrackingNumber));
            if (order == null)
            {
                return;
            }

            var mappedStatus = MapExternalStatus(payload.Status);
            if (mappedStatus.HasValue)
            {
                order.ShippingStatus = mappedStatus.Value;
                order.LastStatusUpdate = DateTime.UtcNow;
            }

            _dbContext.TrackingEvents.Add(new TrackingEvents
            {
                OrderID = order.OrderID,
                Status = mappedStatus ?? order.ShippingStatus,
                Message = payload.Message,
                Location = payload.Location,
                OccurredAt = payload.OccurredAt ?? DateTime.UtcNow,
                Source = $"Webhook:{carrierCode}",
                ExternalStatus = payload.Status,
                RawPayload = payload.RawJson
            });

            await _dbContext.SaveChangesAsync();
        }

        private static ShippingStatusEntity? MapExternalStatus(string? status)
        {
            if (string.IsNullOrWhiteSpace(status)) return null;
            var normalized = status.Trim().ToLowerInvariant();
            return normalized switch
            {
                "shipped" => ShippingStatusEntity.Shipped,
                "in_transit" => ShippingStatusEntity.InTransit,
                "in transit" => ShippingStatusEntity.InTransit,
                "customs" => ShippingStatusEntity.AtCustoms,
                "at_customs" => ShippingStatusEntity.AtCustoms,
                "out_for_delivery" => ShippingStatusEntity.OutForDelivery,
                "out for delivery" => ShippingStatusEntity.OutForDelivery,
                "delivered" => ShippingStatusEntity.Delivered,
                "returned" => ShippingStatusEntity.Returned,
                "cancelled" => ShippingStatusEntity.Cancelled,
                _ => null
            };
        }
    }
}