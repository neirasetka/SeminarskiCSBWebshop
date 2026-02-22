using AutoMapper;
using CBSWebshopSeminarski.Model.Models;
using CBSWebshopSeminarski.Model.ViewModels;
using CBSWebshopSeminarski.Services.Interfaces;
using CSBWebshopSeminarski.Core.Entities;
using CSBWebshopSeminarski.Database;
using Microsoft.EntityFrameworkCore;

namespace CBSWebshopSeminarski.Services.Services
{
    public class ReportsService : IReportsService
    {
        private readonly CocoSunBagsWebshopDbContext _dbContext;
        private readonly IMapper _mapper;

        public ReportsService(CocoSunBagsWebshopDbContext dbContext, IMapper mapper)
        {
            _dbContext = dbContext;
            _mapper = mapper;
        }

        public async Task<SalesSummaryVM> GetSalesSummary(DateTime? fromDateUtc, DateTime? toDateUtc)
        {
            var purchasesQuery = _dbContext.Purchases.AsQueryable();
            if (fromDateUtc.HasValue)
            {
                purchasesQuery = purchasesQuery.Where(p => p.PurchaseDate >= fromDateUtc.Value);
            }
            if (toDateUtc.HasValue)
            {
                purchasesQuery = purchasesQuery.Where(p => p.PurchaseDate <= toDateUtc.Value);
            }

            var ordersQuery = _dbContext.Orders.AsQueryable();
            if (fromDateUtc.HasValue)
            {
                ordersQuery = ordersQuery.Where(o => o.Date >= fromDateUtc.Value);
            }
            if (toDateUtc.HasValue)
            {
                ordersQuery = ordersQuery.Where(o => o.Date <= toDateUtc.Value);
            }

            var totalPurchases = await purchasesQuery.CountAsync();
            var totalOrders = await ordersQuery.CountAsync();

            var totalRevenue = await purchasesQuery
                .Select(p => (decimal)p.Price)
                .DefaultIfEmpty(0m)
                .SumAsync();

            decimal averageOrderValue = 0m;
            if (totalPurchases > 0)
            {
                averageOrderValue = totalRevenue / totalPurchases;
            }

            return new SalesSummaryVM
            {
                TotalOrders = totalOrders,
                TotalPurchases = totalPurchases,
                TotalRevenue = totalRevenue,
                AverageOrderValue = decimal.Round(averageOrderValue, 2),
                FromDateUtc = fromDateUtc,
                ToDateUtc = toDateUtc
            };
        }

        public async Task<List<RevenueByDayPointVM>> GetRevenueByDay(DateTime? fromDateUtc, DateTime? toDateUtc)
        {
            var purchasesQuery = _dbContext.Purchases.AsQueryable();
            if (fromDateUtc.HasValue)
            {
                purchasesQuery = purchasesQuery.Where(p => p.PurchaseDate >= fromDateUtc.Value);
            }
            if (toDateUtc.HasValue)
            {
                purchasesQuery = purchasesQuery.Where(p => p.PurchaseDate <= toDateUtc.Value);
            }

            var grouped = await purchasesQuery
                .GroupBy(p => new DateTime(p.PurchaseDate.Year, p.PurchaseDate.Month, p.PurchaseDate.Day, 0, 0, 0, DateTimeKind.Utc))
                .Select(g => new RevenueByDayPointVM
                {
                    DayUtc = g.Key,
                    Revenue = g.Select(x => (decimal)x.Price).DefaultIfEmpty(0m).Sum(),
                    NumPurchases = g.Count()
                })
                .OrderBy(x => x.DayUtc)
                .ToListAsync();

            return grouped;
        }

        public async Task<List<TopProductVM>> GetTopProducts(DateTime? fromDateUtc, DateTime? toDateUtc, int take = 10)
        {
            var orderItems = _dbContext.OrderItems
                .Include(oi => oi.Bag)
                .Include(oi => oi.Belt)
                .Include(oi => oi.Order)
                .AsQueryable();

            if (fromDateUtc.HasValue)
            {
                orderItems = orderItems.Where(oi => oi.Order.Date >= fromDateUtc.Value);
            }
            if (toDateUtc.HasValue)
            {
                orderItems = orderItems.Where(oi => oi.Order.Date <= toDateUtc.Value);
            }

            var productAgg = await orderItems
                .Select(oi => new
                {
                    ProductType = oi.Bag != null && oi.Bag.BagID != null ? "Bag" : "Belt",
                    ProductId = oi.Bag != null && oi.Bag.BagID != null ? oi.Bag.BagID.Value : oi.Belt.BeltID,
                    ProductName = oi.Bag != null && oi.Bag.BagID != null ? oi.Bag.BagName : oi.Belt.BeltName,
                    Quantity = oi.Quantity ?? 0,
                    LineRevenue = (decimal)(oi.Price ?? 0f) * (decimal)(oi.Quantity ?? 0)
                })
                .GroupBy(x => new { x.ProductType, x.ProductId, x.ProductName })
                .Select(g => new TopProductVM
                {
                    ProductType = g.Key.ProductType,
                    ProductId = g.Key.ProductId,
                    ProductName = g.Key.ProductName,
                    QuantitySold = g.Sum(x => x.Quantity),
                    Revenue = g.Sum(x => x.LineRevenue)
                })
                .OrderByDescending(x => x.QuantitySold)
                .ThenByDescending(x => x.Revenue)
                .Take(take)
                .ToListAsync();

            return productAgg;
        }

        public async Task<List<Bag>> GetTopSellingBags(int take = 6)
        {
            var topBagIds = await _dbContext.OrderItems
                .Where(oi => oi.BagID > 0)
                .GroupBy(oi => oi.BagID)
                .Select(g => new { BagId = g.Key, TotalQuantity = g.Sum(x => x.Quantity ?? 0) })
                .OrderByDescending(x => x.TotalQuantity)
                .Take(take)
                .Select(x => x.BagId)
                .ToListAsync();

            if (topBagIds.Count == 0)
            {
                return new List<Bag>();
            }

            var bags = await _dbContext.Bags
                .Include(b => b.BagType)
                .Where(b => topBagIds.Contains(b.BagID.Value))
                .ToListAsync();

            var bagDict = bags.ToDictionary(b => b.BagID);
            return topBagIds
                .Where(id => bagDict.ContainsKey(id))
                .Select(id => _mapper.Map<Bag>(bagDict[id]))
                .ToList();
        }
    }
}
