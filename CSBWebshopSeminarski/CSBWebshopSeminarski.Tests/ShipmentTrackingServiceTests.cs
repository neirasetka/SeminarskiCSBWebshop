using System;
using System.Linq;
using System.Threading.Tasks;
using AutoMapper;
using CBSWebshopSeminarski.Model.Requests;
using CBSWebshopSeminarski.Services.Services;
using CSBWebshopSeminarski.Core.Entities;
using CSBWebshopSeminarski.Database;
using CSBWebshopSeminarski.Mapper;
using Microsoft.EntityFrameworkCore;
using Xunit;

namespace CSBWebshopSeminarski.Tests
{
	public class ShipmentTrackingServiceTests
	{
		private static CocoSunBagsWebshopDbContext CreateDbContext(string dbName)
		{
			var options = new DbContextOptionsBuilder<CocoSunBagsWebshopDbContext>()
				.UseInMemoryDatabase(databaseName: dbName)
				.Options;
			return new CocoSunBagsWebshopDbContext(options);
		}

		private static IMapper CreateMapper()
		{
			var cfg = new MapperConfiguration(cfg => cfg.AddProfile(new CocoSunBagsWebshopProfile()));
			return cfg.CreateMapper();
		}

		[Fact]
		public async Task UpdateStatusAsync_AddsTrackingEvent_AndUpdatesStatus()
		{
			using var db = CreateDbContext(nameof(UpdateStatusAsync_AddsTrackingEvent_AndUpdatesStatus));
			var order = new Orders { OrderID = 100, OrderNumber = "ORD-100", ShippingStatus = ShippingStatus.Pending };
			db.Orders.Add(order);
			await db.SaveChangesAsync();

			var service = new ShipmentTrackingService(db, CreateMapper());
			await service.UpdateStatusAsync(100, new UpdateShippingStatusRequest
			{
				Status = CBSWebshopSeminarski.Model.Models.ShippingStatus.Shipped,
				Message = "Package shipped",
				Location = "Sarajevo",
				OccurredAt = DateTime.UtcNow
			});

			var updated = await db.Orders.Include(o => o.TrackingEvents).FirstAsync();
			Assert.Equal(ShippingStatus.Shipped, updated.ShippingStatus);
			Assert.Single(updated.TrackingEvents);
		}

		[Fact]
		public async Task HandleCarrierWebhookAsync_MapsExternalStatus_AndPersistsEvent()
		{
			using var db = CreateDbContext(nameof(HandleCarrierWebhookAsync_MapsExternalStatus_AndPersistsEvent));
			var order = new Orders { OrderID = 200, OrderNumber = "ORD-200", ShippingStatus = ShippingStatus.Pending, TrackingNumber = "TRK-1" };
			db.Orders.Add(order);
			await db.SaveChangesAsync();

			var service = new ShipmentTrackingService(db, CreateMapper());
			await service.HandleCarrierWebhookAsync("dhl", new CarrierWebhookPayload
			{
				TrackingNumber = "TRK-1",
				Status = "delivered",
				Message = "Delivered",
				Location = "Mostar",
				OccurredAt = DateTime.UtcNow,
				RawJson = "{...}"
			});

			var updated = await db.Orders.Include(o => o.TrackingEvents).FirstAsync();
			Assert.Equal(ShippingStatus.Delivered, updated.ShippingStatus);
			Assert.Single(updated.TrackingEvents);
			var evt = updated.TrackingEvents.Single();
			Assert.Equal("Webhook:dhl", evt.Source);
			Assert.Equal("delivered", evt.ExternalStatus);
		}
	}
}

