using System.Collections.Generic;
using System.Threading;
using System.Threading.Tasks;
using CSBWebshopSeminarski.Controllers;
using CSBWebshopSeminarski.Core.Entities;
using CSBWebshopSeminarski.Database;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Xunit;
using Stripe;

namespace CSBWebshopSeminarski.Tests
{
	public class PaymentsControllerTests
	{
		private static CocoSunBagsWebshopDbContext CreateDbContext(string dbName)
		{
			var options = new DbContextOptionsBuilder<CocoSunBagsWebshopDbContext>()
				.UseInMemoryDatabase(databaseName: dbName)
				.Options;
			return new CocoSunBagsWebshopDbContext(options);
		}

		[Fact]
		public async Task CreatePaymentIntent_ReturnsNotFound_WhenOrderMissing()
		{
			using var db = CreateDbContext(nameof(CreatePaymentIntent_ReturnsNotFound_WhenOrderMissing));
			var controller = new PaymentsController(db);
			var result = await controller.CreatePaymentIntent(new CBSWebshopSeminarski.Model.Requests.CreatePaymentIntentRequest { OrderID = 999 });
			Assert.IsType<NotFoundObjectResult>(result.Result);
		}
	}
}

