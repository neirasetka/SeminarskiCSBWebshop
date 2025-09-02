using System.Collections.Generic;
using System.Threading.Tasks;
using CBSWebshopSeminarski.Services.Services;
using CSBWebshopSeminarski.Core.Entities;
using CSBWebshopSeminarski.Database;
using Microsoft.EntityFrameworkCore;
using Xunit;

namespace CSBWebshopSeminarski.Tests
{
	public class PaymentsServiceTests
	{
		private static CocoSunBagsWebshopDbContext CreateDbContext(string dbName)
		{
			var options = new DbContextOptionsBuilder<CocoSunBagsWebshopDbContext>()
				.UseInMemoryDatabase(databaseName: dbName)
				.Options;
			return new CocoSunBagsWebshopDbContext(options);
		}

		[Fact]
		public async Task HandlePaymentSucceededAsync_MarksOrderPaid_AndCreatesPurchase_WhenNotExists()
		{
			using var db = CreateDbContext(nameof(HandlePaymentSucceededAsync_MarksOrderPaid_AndCreatesPurchase_WhenNotExists));
			var order = new Orders { OrderID = 1, OrderNumber = "ORD-1", Price = 100, UserID = 5, PaymentStatus = PaymentStatus.Pending, User = new Users { UserID = 5, UserName = "test" } };
			db.Orders.Add(order);
			await db.SaveChangesAsync();

			var service = new PaymentsService(db);
			var metadata = new Dictionary<string, string> { { "order_id", "1" } };

			await service.HandlePaymentSucceededAsync("pi_123", metadata);

			var updated = await db.Orders.FirstAsync();
			Assert.Equal(PaymentStatus.Paid, updated.PaymentStatus);
			Assert.Single(db.Purchases);
			var purchase = await db.Purchases.FirstAsync();
			Assert.Equal("pi_123", purchase.StripeId);
			Assert.Equal(order.OrderID, purchase.OrderID);
		}

		[Fact]
		public async Task HandlePaymentSucceededAsync_Idempotent_WhenPurchaseAlreadyExists()
		{
			using var db = CreateDbContext(nameof(HandlePaymentSucceededAsync_Idempotent_WhenPurchaseAlreadyExists));
			var order = new Orders { OrderID = 2, OrderNumber = "ORD-2", Price = 50, UserID = 6, PaymentStatus = PaymentStatus.Pending, User = new Users { UserID = 6, UserName = "user" } };
			db.Orders.Add(order);
			db.Purchases.Add(new Purchases { OrderID = order.OrderID, OrderNumber = order.OrderNumber, Price = order.Price, UserID = order.UserID, Username = "user", StripeId = "pi_existing" });
			await db.SaveChangesAsync();

			var service = new PaymentsService(db);
			var metadata = new Dictionary<string, string> { { "order_id", "2" } };

			await service.HandlePaymentSucceededAsync("pi_existing", metadata);

			Assert.Equal(1, await db.Purchases.CountAsync());
		}

		[Fact]
		public async Task HandlePaymentFailedAsync_SetsOrderFailed_WhenOrderFound()
		{
			using var db = CreateDbContext(nameof(HandlePaymentFailedAsync_SetsOrderFailed_WhenOrderFound));
			var order = new Orders { OrderID = 3, OrderNumber = "ORD-3", Price = 75, UserID = 7, PaymentStatus = PaymentStatus.Pending };
			db.Orders.Add(order);
			await db.SaveChangesAsync();

			var service = new PaymentsService(db);
			var metadata = new Dictionary<string, string> { { "order_id", "3" } };

			await service.HandlePaymentFailedAsync("pi_456", metadata, "insufficient_funds");

			var updated = await db.Orders.FirstAsync();
			Assert.Equal(PaymentStatus.Failed, updated.PaymentStatus);
		}
	}
}