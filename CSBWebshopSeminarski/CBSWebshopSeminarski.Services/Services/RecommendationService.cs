using CBSWebshopSeminarski.Model.Models;
using CBSWebshopSeminarski.Services.Interfaces;
using CSBWebshopSeminarski.Core.Entities;
using CSBWebshopSeminarski.Database;
using Microsoft.EntityFrameworkCore;

namespace CBSWebshopSeminarski.Services.Services
{
    public class RecommendationService : IRecommendationService
    {
        private readonly CocoSunBagsWebshopDbContext _context;

        // Weight constants for profile building (documented in recommender-dokumentacija.md)
        private const double FavoriteTypeWeight = 3.0;
        private const double RatedTypeWeight = 2.0;
        private const double PurchasedTypeWeight = 1.0;
        private const double TypeMatchMultiplier = 5.0;
        private const double MaxPriceSimilarityBonus = 5.0;
        private const double PopularityPurchaseMultiplier = 0.5;
        private const double PopularityRatingMultiplier = 2.0;
        private const double MinRatingForBonus = 3.5;

        public RecommendationService(CocoSunBagsWebshopDbContext context)
        {
            _context = context;
        }

        public Task<List<RecommendedProductDto>> GetRecommendedBags(int userId, int take = 3) =>
            GetRecommendationsAsync(userId, take, ProductKind.Bag);

        public Task<List<RecommendedProductDto>> GetRecommendedBelts(int userId, int take = 3) =>
            GetRecommendationsAsync(userId, take, ProductKind.Belt);

        private enum ProductKind { Bag, Belt }

        private sealed class UserProductProfile
        {
            public Dictionary<int, double> TypeWeights { get; } = new();
            public List<decimal> ReferencePrices { get; } = new();
            public bool HasTypeSignals => TypeWeights.Count > 0;
            public bool HasAnySignals => TypeWeights.Count > 0 || ReferencePrices.Count > 0;

            public decimal? PreferredPrice =>
                ReferencePrices.Count > 0 ? ReferencePrices.Average() : null;
        }

        private async Task<List<RecommendedProductDto>> GetRecommendationsAsync(
            int userId, int take, ProductKind kind)
        {
            take = Math.Max(1, take);
            if (userId <= 0)
                return await GetPopularFallbackAsync(take, new HashSet<int>(), kind);

            var excludedIds = await GetExcludedProductIdsAsync(userId, kind);
            var profile = await BuildUserProfileAsync(userId, kind);

            if (!profile.HasTypeSignals)
                return await GetPopularFallbackAsync(take, excludedIds, kind);

            return kind == ProductKind.Bag
                ? await ScoreAndRankBagsAsync(profile, excludedIds, take)
                : await ScoreAndRankBeltsAsync(profile, excludedIds, take);
        }

        private async Task<UserProductProfile> BuildUserProfileAsync(int userId, ProductKind kind)
        {
            var profile = new UserProductProfile();

            if (kind == ProductKind.Bag)
            {
                var favorites = await _context.Favorites
                    .AsNoTracking()
                    .Where(f => f.UserID == userId && f.BagID.HasValue)
                    .Include(f => f.Bag)
                    .ToListAsync();

                foreach (var fav in favorites)
                {
                    var typeId = fav.Bag?.BagTypeID ?? 0;
                    if (typeId > 0)
                        AddTypeWeight(profile.TypeWeights, typeId, FavoriteTypeWeight);
                    if (fav.Bag != null)
                        profile.ReferencePrices.Add(fav.Bag.Price);
                }

                var highRatings = await _context.Rates
                    .AsNoTracking()
                    .Where(r => r.UserID == userId && r.BagID.HasValue && r.Rating >= 3)
                    .Include(r => r.Bag)
                    .ToListAsync();

                foreach (var rate in highRatings)
                {
                    var typeId = rate.Bag?.BagTypeID ?? 0;
                    if (typeId > 0)
                        AddTypeWeight(profile.TypeWeights, typeId, RatedTypeWeight);
                    if (rate.Bag != null)
                        profile.ReferencePrices.Add(rate.Bag.Price);
                }

                var purchasedBags = await GetPurchasedBagsAsync(userId);
                foreach (var bag in purchasedBags)
                {
                    var typeId = bag.BagTypeID ?? 0;
                    if (typeId > 0)
                        AddTypeWeight(profile.TypeWeights, typeId, PurchasedTypeWeight);
                    profile.ReferencePrices.Add(bag.Price);
                }
            }
            else
            {
                var favorites = await _context.Favorites
                    .AsNoTracking()
                    .Where(f => f.UserID == userId && f.BeltID.HasValue)
                    .Include(f => f.Belt)
                    .ToListAsync();

                foreach (var fav in favorites)
                {
                    if (fav.Belt == null) continue;
                    AddTypeWeight(profile.TypeWeights, fav.Belt.BeltTypeID, FavoriteTypeWeight);
                    profile.ReferencePrices.Add(fav.Belt.Price);
                }

                var highRatings = await _context.Rates
                    .AsNoTracking()
                    .Where(r => r.UserID == userId && r.BeltID.HasValue && r.Rating >= 3)
                    .Include(r => r.Belt)
                    .ToListAsync();

                foreach (var rate in highRatings)
                {
                    if (rate.Belt == null) continue;
                    AddTypeWeight(profile.TypeWeights, rate.Belt.BeltTypeID, RatedTypeWeight);
                    profile.ReferencePrices.Add(rate.Belt.Price);
                }

                var purchasedBelts = await GetPurchasedBeltsAsync(userId);
                foreach (var belt in purchasedBelts)
                {
                    AddTypeWeight(profile.TypeWeights, belt.BeltTypeID, PurchasedTypeWeight);
                    profile.ReferencePrices.Add(belt.Price);
                }
            }

            return profile;
        }

        private async Task<List<Bags>> GetPurchasedBagsAsync(int userId)
        {
            return await _context.Purchases
                .AsNoTracking()
                .Where(p => p.UserID == userId)
                .Include(p => p.Order).ThenInclude(o => o.OrderItems).ThenInclude(oi => oi.Bag)
                .SelectMany(p => p.Order.OrderItems)
                .Where(oi => oi.BagID.HasValue && oi.Bag != null)
                .Select(oi => oi.Bag!)
                .Distinct()
                .ToListAsync();
        }

        private async Task<List<Belts>> GetPurchasedBeltsAsync(int userId)
        {
            return await _context.Purchases
                .AsNoTracking()
                .Where(p => p.UserID == userId)
                .Include(p => p.Order).ThenInclude(o => o.OrderItems).ThenInclude(oi => oi.Belt)
                .SelectMany(p => p.Order.OrderItems)
                .Where(oi => oi.BeltID.HasValue && oi.Belt != null)
                .Select(oi => oi.Belt!)
                .Distinct()
                .ToListAsync();
        }

        private async Task<HashSet<int>> GetExcludedProductIdsAsync(int userId, ProductKind kind)
        {
            var excluded = new HashSet<int>();

            if (kind == ProductKind.Bag)
            {
                var purchased = await _context.Purchases
                    .AsNoTracking()
                    .Where(p => p.UserID == userId)
                    .Include(p => p.Order).ThenInclude(o => o.OrderItems)
                    .SelectMany(p => p.Order.OrderItems)
                    .Where(oi => oi.BagID.HasValue)
                    .Select(oi => oi.BagID!.Value)
                    .Distinct()
                    .ToListAsync();

                var favorited = await _context.Favorites
                    .AsNoTracking()
                    .Where(f => f.UserID == userId && f.BagID.HasValue)
                    .Select(f => f.BagID!.Value)
                    .Distinct()
                    .ToListAsync();

                excluded.UnionWith(purchased);
                excluded.UnionWith(favorited);
            }
            else
            {
                var purchased = await _context.Purchases
                    .AsNoTracking()
                    .Where(p => p.UserID == userId)
                    .Include(p => p.Order).ThenInclude(o => o.OrderItems)
                    .SelectMany(p => p.Order.OrderItems)
                    .Where(oi => oi.BeltID.HasValue)
                    .Select(oi => oi.BeltID!.Value)
                    .Distinct()
                    .ToListAsync();

                var favorited = await _context.Favorites
                    .AsNoTracking()
                    .Where(f => f.UserID == userId && f.BeltID.HasValue)
                    .Select(f => f.BeltID!.Value)
                    .Distinct()
                    .ToListAsync();

                excluded.UnionWith(purchased);
                excluded.UnionWith(favorited);
            }

            return excluded;
        }

        private async Task<List<RecommendedProductDto>> ScoreAndRankBagsAsync(
            UserProductProfile profile, HashSet<int> excludedIds, int take)
        {
            var typeIds = profile.TypeWeights.Keys.ToList();

            var candidates = await _context.Bags
                .AsNoTracking()
                .Where(b => b.BagTypeID.HasValue
                            && typeIds.Contains(b.BagTypeID.Value)
                            && b.BagID.HasValue
                            && !excludedIds.Contains(b.BagID.Value))
                .Include(b => b.BagType)
                .ToListAsync();

            if (candidates.Count == 0)
                return await GetPopularFallbackAsync(take, excludedIds, ProductKind.Bag);

            var candidateIds = candidates.Select(c => c.BagID!.Value).ToList();
            var stats = await GetBagStatsAsync(candidateIds);

            var scored = candidates.Select(bag =>
            {
                var bagId = bag.BagID!.Value;
                var typeId = bag.BagTypeID ?? 0;
                stats.TryGetValue(bagId, out var productStats);

                var (score, reasons) = ComputeScore(
                    profile,
                    typeId,
                    bag.Price,
                    productStats.AvgRating,
                    productStats.PurchaseCount,
                    bag.BagType?.BagName);

                return ToDto(bagId, bag.BagName, bag.Description, bag.Price, bag.Image, "Bag", score, reasons, true);
            })
            .OrderByDescending(x => x.Score)
            .ThenBy(x => x.ProductId)
            .Take(take)
            .ToList();

            return scored;
        }

        private async Task<List<RecommendedProductDto>> ScoreAndRankBeltsAsync(
            UserProductProfile profile, HashSet<int> excludedIds, int take)
        {
            var typeIds = profile.TypeWeights.Keys.ToList();

            var candidates = await _context.Belts
                .AsNoTracking()
                .Where(b => typeIds.Contains(b.BeltTypeID) && !excludedIds.Contains(b.BeltID))
                .Include(b => b.BeltType)
                .ToListAsync();

            if (candidates.Count == 0)
                return await GetPopularFallbackAsync(take, excludedIds, ProductKind.Belt);

            var candidateIds = candidates.Select(c => c.BeltID).ToList();
            var stats = await GetBeltStatsAsync(candidateIds);

            var scored = candidates.Select(belt =>
            {
                stats.TryGetValue(belt.BeltID, out var productStats);

                var (score, reasons) = ComputeScore(
                    profile,
                    belt.BeltTypeID,
                    belt.Price,
                    productStats.AvgRating,
                    productStats.PurchaseCount,
                    belt.BeltType?.BeltName);

                return ToDto(belt.BeltID, belt.BeltName, belt.Description, belt.Price, belt.Image, "Belt", score, reasons, true);
            })
            .OrderByDescending(x => x.Score)
            .ThenBy(x => x.ProductId)
            .Take(take)
            .ToList();

            return scored;
        }

        private (double Score, List<string> Reasons) ComputeScore(
            UserProductProfile profile,
            int typeId,
            decimal price,
            double avgRating,
            int purchaseCount,
            string? typeName)
        {
            double score = 0;
            var reasons = new List<string>();

            if (profile.TypeWeights.TryGetValue(typeId, out var typeWeight))
            {
                var typeScore = typeWeight * TypeMatchMultiplier;
                score += typeScore;
                var label = string.IsNullOrWhiteSpace(typeName) ? "proizvoda" : typeName;
                if (typeWeight >= FavoriteTypeWeight)
                    reasons.Add($"Tip \"{label}\" iz vaših omiljenih");
                else if (typeWeight >= RatedTypeWeight)
                    reasons.Add($"Tip \"{label}\" koji ste visoko ocijenili");
                else
                    reasons.Add($"Tip \"{label}\" sličan vašim kupnjama");
            }

            var preferredPrice = profile.PreferredPrice;
            if (preferredPrice.HasValue && preferredPrice.Value > 0)
            {
                var deviation = Math.Abs((double)(price - preferredPrice.Value) / (double)preferredPrice.Value);
                if (deviation <= 0.25)
                {
                    var priceBonus = MaxPriceSimilarityBonus * (1.0 - deviation / 0.25);
                    score += priceBonus;
                    reasons.Add("Cijena blizu vašeg uobičajenog raspona");
                }
            }

            if (purchaseCount > 0)
            {
                score += purchaseCount * PopularityPurchaseMultiplier;
                reasons.Add($"Popularan kod kupaca ({purchaseCount} kupnji)");
            }

            if (avgRating >= MinRatingForBonus)
            {
                score += avgRating * PopularityRatingMultiplier;
                reasons.Add($"Visoka prosječna ocjena ({avgRating:F1})");
            }

            return (score, reasons);
        }

        private async Task<List<RecommendedProductDto>> GetPopularFallbackAsync(
            int take, HashSet<int> excludedIds, ProductKind kind)
        {
            if (kind == ProductKind.Bag)
            {
                var bags = await _context.Bags
                    .AsNoTracking()
                    .Where(b => b.BagID.HasValue && !excludedIds.Contains(b.BagID.Value))
                    .ToListAsync();

                if (bags.Count == 0) return new List<RecommendedProductDto>();

                var ids = bags.Select(b => b.BagID!.Value).ToList();
                var stats = await GetBagStatsAsync(ids);

                return bags.Select(bag =>
                {
                    var bagId = bag.BagID!.Value;
                    stats.TryGetValue(bagId, out var productStats);
                    var score = productStats.PurchaseCount * PopularityPurchaseMultiplier
                                + (productStats.AvgRating >= MinRatingForBonus
                                    ? productStats.AvgRating * PopularityRatingMultiplier
                                    : 0);

                    var reasons = new List<string> { "Popularan proizvod u ponudi" };
                    if (productStats.PurchaseCount > 0)
                        reasons.Add($"{productStats.PurchaseCount} kupnji");
                    if (productStats.AvgRating >= MinRatingForBonus)
                        reasons.Add($"Prosječna ocjena {productStats.AvgRating:F1}");

                    return ToDto(bagId, bag.BagName, bag.Description, bag.Price, bag.Image, "Bag",
                        score, reasons, false);
                })
                .OrderByDescending(x => x.Score)
                .ThenBy(x => x.ProductId)
                .Take(take)
                .ToList();
            }

            var belts = await _context.Belts
                .AsNoTracking()
                .Where(b => !excludedIds.Contains(b.BeltID))
                .ToListAsync();

            if (belts.Count == 0) return new List<RecommendedProductDto>();

            var beltIds = belts.Select(b => b.BeltID).ToList();
            var beltStats = await GetBeltStatsAsync(beltIds);

            return belts.Select(belt =>
            {
                beltStats.TryGetValue(belt.BeltID, out var productStats);
                var score = productStats.PurchaseCount * PopularityPurchaseMultiplier
                            + (productStats.AvgRating >= MinRatingForBonus
                                ? productStats.AvgRating * PopularityRatingMultiplier
                                : 0);

                var reasons = new List<string> { "Popularan proizvod u ponudi" };
                if (productStats.PurchaseCount > 0)
                    reasons.Add($"{productStats.PurchaseCount} kupnji");
                if (productStats.AvgRating >= MinRatingForBonus)
                    reasons.Add($"Prosječna ocjena {productStats.AvgRating:F1}");

                return ToDto(belt.BeltID, belt.BeltName, belt.Description, belt.Price, belt.Image, "Belt",
                    score, reasons, false);
            })
            .OrderByDescending(x => x.Score)
            .ThenBy(x => x.ProductId)
            .Take(take)
            .ToList();
        }

        private struct ProductStats
        {
            public double AvgRating { get; set; }
            public int PurchaseCount { get; set; }

            public static ProductStats Empty => default;
        }

        private async Task<Dictionary<int, ProductStats>> GetBagStatsAsync(List<int> bagIds)
        {
            if (bagIds.Count == 0) return new Dictionary<int, ProductStats>();

            var ratings = await _context.Rates
                .AsNoTracking()
                .Where(r => r.BagID.HasValue && bagIds.Contains(r.BagID.Value))
                .GroupBy(r => r.BagID)
                .Select(g => new { BagID = g.Key!.Value, Avg = g.Average(r => r.Rating) })
                .ToDictionaryAsync(x => x.BagID, x => x.Avg);

            var purchases = await _context.OrderItems
                .AsNoTracking()
                .Where(oi => oi.BagID.HasValue && bagIds.Contains(oi.BagID.Value))
                .GroupBy(oi => oi.BagID)
                .Select(g => new
                {
                    BagID = g.Key!.Value,
                    Count = g.Sum(x => x.Quantity ?? 1)
                })
                .ToDictionaryAsync(x => x.BagID, x => x.Count);

            return bagIds.ToDictionary(
                id => id,
                id => new ProductStats
                {
                    AvgRating = ratings.TryGetValue(id, out var avg) ? avg : 0,
                    PurchaseCount = purchases.TryGetValue(id, out var count) ? count : 0
                });
        }

        private async Task<Dictionary<int, ProductStats>> GetBeltStatsAsync(List<int> beltIds)
        {
            if (beltIds.Count == 0) return new Dictionary<int, ProductStats>();

            var ratings = await _context.Rates
                .AsNoTracking()
                .Where(r => r.BeltID.HasValue && beltIds.Contains(r.BeltID.Value))
                .GroupBy(r => r.BeltID)
                .Select(g => new { BeltID = g.Key!.Value, Avg = g.Average(r => r.Rating) })
                .ToDictionaryAsync(x => x.BeltID, x => x.Avg);

            var purchases = await _context.OrderItems
                .AsNoTracking()
                .Where(oi => oi.BeltID.HasValue && beltIds.Contains(oi.BeltID.Value))
                .GroupBy(oi => oi.BeltID)
                .Select(g => new
                {
                    BeltID = g.Key!.Value,
                    Count = g.Sum(x => x.Quantity ?? 1)
                })
                .ToDictionaryAsync(x => x.BeltID, x => x.Count);

            return beltIds.ToDictionary(
                id => id,
                id => new ProductStats
                {
                    AvgRating = ratings.TryGetValue(id, out var avg) ? avg : 0,
                    PurchaseCount = purchases.TryGetValue(id, out var count) ? count : 0
                });
        }

        private static void AddTypeWeight(Dictionary<int, double> weights, int typeId, double weight)
        {
            if (typeId <= 0) return;
            weights[typeId] = weights.TryGetValue(typeId, out var existing) ? existing + weight : weight;
        }

        private static RecommendedProductDto ToDto(
            int productId,
            string name,
            string description,
            decimal price,
            byte[] image,
            string productType,
            double score,
            List<string> reasons,
            bool isPersonalized)
        {
            return new RecommendedProductDto
            {
                ProductId = productId,
                ProductName = name,
                Description = description,
                ProductType = productType,
                Price = price,
                Image = image,
                Score = Math.Round(score, 2),
                Reason = string.Join("; ", reasons),
                IsPersonalized = isPersonalized
            };
        }
    }
}
