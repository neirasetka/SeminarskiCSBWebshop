using CSBWebshopSeminarski.Core.Entities;
using Microsoft.EntityFrameworkCore;
using System.Security.Cryptography;
using Microsoft.Extensions.Logging;

namespace CSBWebshopSeminarski.Database
{
    public static class DatabaseSeeder
    {
        public static async Task SeedAllAsync(CocoSunBagsWebshopDbContext context, ILogger logger)
        {
            // Ensure base reference data first
            await EnsureBagTypesAsync(context, logger);
            await EnsureBeltTypesAsync(context, logger);

            // Ensure a demo buyer user (admin is created in Program.cs)
            var buyerUser = await EnsureBuyerUserAsync(context, logger);

            // Products
            var bagTypes = await context.BagTypes.AsNoTracking().ToListAsync();
            var beltTypes = await context.BeltTypes.AsNoTracking().ToListAsync();
            var adminUser = await context.Users.OrderBy(u => u.UserID).FirstOrDefaultAsync();

            var sampleBag = await EnsureBagAsync(context, logger, bagTypes.FirstOrDefault()?.BagTypeID, adminUser?.UserID);
            var sampleBelt = await EnsureBeltAsync(context, logger, beltTypes.FirstOrDefault()?.BeltTypeID, adminUser?.UserID ?? buyerUser.UserID);

            // Orders and related
            var order = await EnsureOrderAsync(context, logger, buyerUser, sampleBag, sampleBelt);
            await EnsureOrderItemsAsync(context, logger, order, sampleBag, sampleBelt);
            await EnsureTrackingEventsAsync(context, logger, order);
            await EnsurePurchaseAndTransactionAsync(context, logger, order, buyerUser);

            // Social/content
            await EnsureFavoritesAsync(context, logger, buyerUser, sampleBag, sampleBelt);
            await EnsureReviewsAsync(context, logger, buyerUser, sampleBag, sampleBelt);
            await EnsureRatesAsync(context, logger, buyerUser, sampleBag, sampleBelt);
            await EnsureLookbookItemsAsync(context, logger, sampleBag, sampleBelt);
            await EnsureSubscribersAsync(context, logger);
            await EnsureNewsAsync(context, logger);
            await EnsureAnnouncementAuditAsync(context, logger);

            // Giveaways
            await EnsureGiveawayAndParticipantsAsync(context, logger);
        }

        private static async Task EnsureBagTypesAsync(CocoSunBagsWebshopDbContext context, ILogger logger)
        {
            if (!await context.BagTypes.AnyAsync())
            {
                await context.BagTypes.AddRangeAsync(new[]
                {
                    new BagTypes { BagName = "Tote" },
                    new BagTypes { BagName = "Crossbody" },
                    new BagTypes { BagName = "Backpack" }
                });
                await context.SaveChangesAsync();
                logger.LogInformation("Seeded BagTypes.");
            }
        }

        private static async Task EnsureBeltTypesAsync(CocoSunBagsWebshopDbContext context, ILogger logger)
        {
            if (!await context.BeltTypes.AnyAsync())
            {
                await context.BeltTypes.AddRangeAsync(new[]
                {
                    new BeltTypes { BeltName = "Leather" },
                    new BeltTypes { BeltName = "Fabric" }
                });
                await context.SaveChangesAsync();
                logger.LogInformation("Seeded BeltTypes.");
            }
        }

        private static async Task<Users> EnsureBuyerUserAsync(CocoSunBagsWebshopDbContext context, ILogger logger)
        {
            var buyer = await context.Users.FirstOrDefaultAsync(u => u.UserName == "buyer");
            if (buyer != null)
            {
                return buyer;
            }

            var salt = GenerateSalt();
            var hash = GenerateHash(salt, "Buyer123!");
            buyer = new Users
            {
                Name = "Default",
                Surname = "Buyer",
                Email = "buyer@example.com",
                Phone = "+38761000000",
                UserName = "buyer",
                PasswordSalt = salt,
                PasswordHash = hash,
                Image = Array.Empty<byte>()
            };
            await context.Users.AddAsync(buyer);
            await context.SaveChangesAsync();
            logger.LogInformation("Seeded Buyer user.");

            // Ensure Buyer role assignment if role exists
            var buyerRole = await context.Roles.FirstOrDefaultAsync(r => r.RoleName == "Buyer");
            if (buyerRole != null)
            {
                var hasRole = await context.UserRoles.AnyAsync(ur => ur.UserID == buyer.UserID && ur.RolesID == buyerRole.RoleID);
                if (!hasRole)
                {
                    await context.UserRoles.AddAsync(new UserRoles { UserID = buyer.UserID, RolesID = buyerRole.RoleID });
                    await context.SaveChangesAsync();
                }
            }
            return buyer;
        }

        private static async Task<Bags> EnsureBagAsync(CocoSunBagsWebshopDbContext context, ILogger logger, int? bagTypeId, int? ownerUserId)
        {
            var bag = await context.Bags.FirstOrDefaultAsync(b => b.Code == "BAG-001");
            if (bag != null)
            {
                return bag;
            }

            bag = new Bags
            {
                BagName = "Coco Tote",
                BagTypeID = bagTypeId,
                Description = "Spacious everyday tote bag.",
                Code = "BAG-001",
                Price = 129.99f,
                Image = Array.Empty<byte>(),
                UserID = ownerUserId
            };
            await context.Bags.AddAsync(bag);
            await context.SaveChangesAsync();
            logger.LogInformation("Seeded sample Bag.");
            return bag;
        }

        private static async Task<Belts> EnsureBeltAsync(CocoSunBagsWebshopDbContext context, ILogger logger, int? beltTypeId, int ownerUserId)
        {
            var belt = await context.Belts.FirstOrDefaultAsync(b => b.Code == "BELT-001");
            if (belt != null)
            {
                return belt;
            }

            belt = new Belts
            {
                BeltName = "Classic Leather Belt",
                BeltTypeID = beltTypeId ?? 0,
                Description = "Genuine leather belt with metal buckle.",
                Code = "BELT-001",
                Price = 49.99f,
                Image = Array.Empty<byte>(),
                UserID = ownerUserId
            };
            await context.Belts.AddAsync(belt);
            await context.SaveChangesAsync();
            logger.LogInformation("Seeded sample Belt.");
            return belt;
        }

        private static async Task<Orders> EnsureOrderAsync(CocoSunBagsWebshopDbContext context, ILogger logger, Users buyerUser, Bags bag, Belts belt)
        {
            var order = await context.Orders.FirstOrDefaultAsync(o => o.OrderNumber == "ORD-1001");
            if (order != null)
            {
                return order;
            }

            order = new Orders
            {
                OrderNumber = "ORD-1001",
                Date = DateTime.UtcNow.Date,
                Price = bag.Price + belt.Price,
                UserID = buyerUser.UserID,
                PaymentStatus = PaymentStatus.Pending,
                ShippingStatus = ShippingStatus.Pending,
                TrackingNumber = null,
                CarrierCode = null
            };
            await context.Orders.AddAsync(order);
            await context.SaveChangesAsync();
            logger.LogInformation("Seeded sample Order.");
            return order;
        }

        private static async Task EnsureOrderItemsAsync(CocoSunBagsWebshopDbContext context, ILogger logger, Orders order, Bags bag, Belts belt)
        {
            if (!await context.OrderItems.AnyAsync(oi => oi.OrderID == order.OrderID))
            {
                await context.OrderItems.AddAsync(new OrderItems
                {
                    OrderID = order.OrderID,
                    BagID = bag.BagID ?? 0,
                    BeltID = belt.BeltID,
                    Quantity = 1,
                    Price = order.Price,
                    Discount = 0
                });
                await context.SaveChangesAsync();
                logger.LogInformation("Seeded OrderItems.");
            }
        }

        private static async Task EnsurePurchaseAndTransactionAsync(CocoSunBagsWebshopDbContext context, ILogger logger, Orders order, Users buyerUser)
        {
            if (!await context.Purchases.AnyAsync(p => p.OrderID == order.OrderID))
            {
                await context.Purchases.AddAsync(new Purchases
                {
                    OrderID = order.OrderID,
                    UserID = buyerUser.UserID,
                    PurchaseDate = DateTime.UtcNow,
                    Price = order.Price,
                    Username = buyerUser.UserName,
                    OrderNumber = order.OrderNumber,
                    StripeId = "pi_test_123"
                });
                await context.SaveChangesAsync();
                logger.LogInformation("Seeded Purchase.");
            }

            if (!await context.Transactions.AnyAsync(t => t.OrderID == order.OrderID))
            {
                await context.Transactions.AddAsync(new Transactions
                {
                    OrderID = order.OrderID,
                    UserID = buyerUser.UserID,
                    TransactionDate = DateTime.UtcNow,
                    Price = order.Price,
                    Username = buyerUser.UserName,
                    OrderNumber = order.OrderNumber
                });
                await context.SaveChangesAsync();
                logger.LogInformation("Seeded Transaction.");
            }
        }

        private static async Task EnsureTrackingEventsAsync(CocoSunBagsWebshopDbContext context, ILogger logger, Orders order)
        {
            if (!await context.TrackingEvents.AnyAsync(te => te.OrderID == order.OrderID))
            {
                await context.TrackingEvents.AddRangeAsync(new[]
                {
                    new TrackingEvents
                    {
                        OrderID = order.OrderID,
                        Status = ShippingStatus.Pending,
                        Message = "Order created",
                        Location = "Warehouse",
                        OccurredAt = DateTime.UtcNow.AddHours(-6),
                        Source = "System"
                    },
                    new TrackingEvents
                    {
                        OrderID = order.OrderID,
                        Status = ShippingStatus.Shipped,
                        Message = "Order shipped",
                        Location = "Distribution Center",
                        OccurredAt = DateTime.UtcNow.AddHours(-2),
                        Source = "Carrier"
                    }
                });
                order.ShippingStatus = ShippingStatus.InTransit;
                order.LastStatusUpdate = DateTime.UtcNow;
                order.EstimatedDeliveryDate = DateTime.UtcNow.AddDays(3);
                await context.SaveChangesAsync();
                logger.LogInformation("Seeded TrackingEvents.");
            }
        }

        private static async Task EnsureFavoritesAsync(CocoSunBagsWebshopDbContext context, ILogger logger, Users buyerUser, Bags bag, Belts belt)
        {
            if (!await context.Favorites.AnyAsync(f => f.UserID == buyerUser.UserID && f.BagID == bag.BagID))
            {
                await context.Favorites.AddAsync(new Favorites { UserID = buyerUser.UserID, BagID = bag.BagID });
            }
            if (!await context.Favorites.AnyAsync(f => f.UserID == buyerUser.UserID && f.BeltID == belt.BeltID))
            {
                await context.Favorites.AddAsync(new Favorites { UserID = buyerUser.UserID, BeltID = belt.BeltID });
            }
            await context.SaveChangesAsync();
            logger.LogInformation("Seeded Favorites.");
        }

        private static async Task EnsureReviewsAsync(CocoSunBagsWebshopDbContext context, ILogger logger, Users buyerUser, Bags bag, Belts belt)
        {
            if (!await context.Reviews.AnyAsync(r => r.UserID == buyerUser.UserID && r.BagID == (bag.BagID ?? 0)))
            {
                await context.Reviews.AddAsync(new Reviews
                {
                    UserID = buyerUser.UserID,
                    BagID = bag.BagID ?? 0,
                    BeltID = belt.BeltID,
                    Date = DateTime.UtcNow.AddDays(-1),
                    Comment = "Great quality and design!",
                    Status = ReviewStatus.Approved
                });
                await context.SaveChangesAsync();
                logger.LogInformation("Seeded Reviews.");
            }
        }

        private static async Task EnsureRatesAsync(CocoSunBagsWebshopDbContext context, ILogger logger, Users buyerUser, Bags bag, Belts belt)
        {
            if (!await context.Rates.AnyAsync(r => r.UserID == buyerUser.UserID && r.BagID == (bag.BagID ?? 0)))
            {
                await context.Rates.AddAsync(new Rates
                {
                    UserID = buyerUser.UserID,
                    BagID = bag.BagID ?? 0,
                    BeltID = belt.BeltID,
                    Rating = 5
                });
                await context.SaveChangesAsync();
                logger.LogInformation("Seeded Rates.");
            }
        }

        private static async Task EnsureLookbookItemsAsync(CocoSunBagsWebshopDbContext context, ILogger logger, Bags bag, Belts belt)
        {
            if (!await context.LookbookItems.AnyAsync())
            {
                await context.LookbookItems.AddRangeAsync(new[]
                {
                    new LookbookItems
                    {
                        Title = "Summer Essentials",
                        Caption = "Light and stylish.",
                        Tags = "summer,casual",
                        SortOrder = 1,
                        IsFeatured = true,
                        CreatedAt = DateTime.UtcNow,
                        Image = Array.Empty<byte>(),
                        BagID = bag.BagID,
                        Occasion = OccasionType.Weekend,
                        Style = StyleType.Minimalist,
                        Season = SeasonType.Summer
                    },
                    new LookbookItems
                    {
                        Title = "Classic Office",
                        Caption = "Timeless combination.",
                        Tags = "work,classic",
                        SortOrder = 2,
                        IsFeatured = false,
                        CreatedAt = DateTime.UtcNow,
                        Image = Array.Empty<byte>(),
                        BeltID = belt.BeltID,
                        Occasion = OccasionType.Work,
                        Style = StyleType.Classic,
                        Season = SeasonType.AllSeason
                    }
                });
                await context.SaveChangesAsync();
                logger.LogInformation("Seeded LookbookItems.");
            }
        }

        private static async Task EnsureSubscribersAsync(CocoSunBagsWebshopDbContext context, ILogger logger)
        {
            if (!await context.Subscribers.AnyAsync())
            {
                await context.Subscribers.AddRangeAsync(new[]
                {
                    new Subscribers { Email = "user1@example.com", IsSubscribedToGiveaway = true, IsSubscribedToNewCollections = true },
                    new Subscribers { Email = "user2@example.com", IsSubscribedToGiveaway = false, IsSubscribedToNewCollections = true }
                });
                await context.SaveChangesAsync();
                logger.LogInformation("Seeded Subscribers.");
            }
        }

        private static async Task EnsureNewsAsync(CocoSunBagsWebshopDbContext context, ILogger logger)
        {
            if (!await context.News.AnyAsync())
            {
                await context.News.AddAsync(new NewsItem
                {
                    PublishedAtUtc = DateTime.UtcNow,
                    Title = "New collection has arrived.",
                    Body = "Take a look at our new bags and belts.",
                    Segment = "AllSubscribers",
                    LaunchDate = DateTime.UtcNow.AddDays(7),
                    ProductName = "Coco Tote",
                    Price = 129.99m,
                    Color = "Black",
                    CreatedBy = "seeder"
                });
                await context.SaveChangesAsync();
                logger.LogInformation("Seeded News.");
            }
        }

        private static async Task EnsureAnnouncementAuditAsync(CocoSunBagsWebshopDbContext context, ILogger logger)
        {
            if (!await context.AnnouncementAudits.AnyAsync())
            {
                await context.AnnouncementAudits.AddAsync(new AnnouncementAudit
                {
                    SentAtUtc = DateTime.UtcNow,
                    InitiatedBy = "seeder",
                    Subject = "Welcome Campaign",
                    TemplateKey = "welcome_email",
                    Segment = "AllSubscribers",
                    RecipientsCount = 2,
                    IsSuccess = true,
                    ErrorMessage = null
                });
                await context.SaveChangesAsync();
                logger.LogInformation("Seeded AnnouncementAudit.");
            }
        }

        private static async Task EnsureGiveawayAndParticipantsAsync(CocoSunBagsWebshopDbContext context, ILogger logger)
        {
            if (!await context.Giveaways.AnyAsync())
            {
                var giveaway = new Giveaways
                {
                    Title = "Back to School Giveaway",
                    StartDate = DateTime.UtcNow.AddDays(-10),
                    EndDate = DateTime.UtcNow.AddDays(10),
                    IsClosed = false
                };
                await context.Giveaways.AddAsync(giveaway);
                await context.SaveChangesAsync();

                var participants = new List<Participants>
                {
                    new Participants { Name = "Amar", Email = "amar@example.com", EntryDate = DateTime.UtcNow.AddDays(-5), GiveawayId = giveaway.Id },
                    new Participants { Name = "Lejla", Email = "lejla@example.com", EntryDate = DateTime.UtcNow.AddDays(-4), GiveawayId = giveaway.Id },
                    new Participants { Name = "Tarik", Email = "tarik@example.com", EntryDate = DateTime.UtcNow.AddDays(-3), GiveawayId = giveaway.Id }
                };
                await context.Participants.AddRangeAsync(participants);
                await context.SaveChangesAsync();

                // Set winner
                giveaway.WinnerParticipantId = participants[1].Id;
                await context.SaveChangesAsync();
                logger.LogInformation("Seeded Giveaways and Participants.");
            }
        }

        private static string GenerateSalt()
        {
            var saltBytes = RandomNumberGenerator.GetBytes(16);
            return Convert.ToBase64String(saltBytes);
        }

        private static string GenerateHash(string salt, string password)
        {
            var saltBytes = Convert.FromBase64String(salt);
            using var deriveBytes = new Rfc2898DeriveBytes(password, saltBytes, 100_000, HashAlgorithmName.SHA256);
            var key = deriveBytes.GetBytes(32);
            return Convert.ToBase64String(key);
        }
    }
}
