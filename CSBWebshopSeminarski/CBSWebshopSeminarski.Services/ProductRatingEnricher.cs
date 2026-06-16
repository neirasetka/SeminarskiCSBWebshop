using CBSWebshopSeminarski.Model.Models;
using CSBWebshopSeminarski.Database;
using Microsoft.EntityFrameworkCore;

namespace CBSWebshopSeminarski.Services
{
    /// <summary>Dopunjava Bag/Belt DTO prosječnom ocjenom iz tablice Rates.</summary>
    public static class ProductRatingEnricher
    {
        public static async Task EnrichBagsAsync(CocoSunBagsWebshopDbContext context, IList<Bag> bags)
        {
            if (bags.Count == 0)
                return;

            var bagIds = bags.Select(b => b.BagID).ToList();
            var averages = await context.Rates
                .Where(r => r.BagID.HasValue && bagIds.Contains(r.BagID.Value))
                .GroupBy(r => r.BagID!.Value)
                .Select(g => new { Id = g.Key, Average = g.Average(r => r.Rating) })
                .ToDictionaryAsync(x => x.Id, x => (decimal)x.Average);

            foreach (var bag in bags)
            {
                if (averages.TryGetValue(bag.BagID, out var average))
                    bag.AverageRating = average;
            }
        }

        public static async Task EnrichBeltsAsync(CocoSunBagsWebshopDbContext context, IList<Belt> belts)
        {
            if (belts.Count == 0)
                return;

            var beltIds = belts.Select(b => b.BeltID).ToList();
            var averages = await context.Rates
                .Where(r => r.BeltID.HasValue && beltIds.Contains(r.BeltID.Value))
                .GroupBy(r => r.BeltID!.Value)
                .Select(g => new { Id = g.Key, Average = g.Average(r => r.Rating) })
                .ToDictionaryAsync(x => x.Id, x => (decimal)x.Average);

            foreach (var belt in belts)
            {
                if (averages.TryGetValue(belt.BeltID, out var average))
                    belt.AverageRating = average;
            }
        }

        public static async Task<decimal?> GetBagAverageOrNullAsync(CocoSunBagsWebshopDbContext context, int bagId)
        {
            var ratings = await context.Rates
                .Where(r => r.BagID == bagId)
                .Select(r => r.Rating)
                .ToListAsync();
            return ratings.Count == 0 ? null : (decimal)ratings.Average();
        }

        public static async Task<decimal?> GetBeltAverageOrNullAsync(CocoSunBagsWebshopDbContext context, int beltId)
        {
            var ratings = await context.Rates
                .Where(r => r.BeltID == beltId)
                .Select(r => r.Rating)
                .ToListAsync();
            return ratings.Count == 0 ? null : (decimal)ratings.Average();
        }
    }
}
