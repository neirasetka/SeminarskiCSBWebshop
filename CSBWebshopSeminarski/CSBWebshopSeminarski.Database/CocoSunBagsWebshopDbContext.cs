using CSBWebshopSeminarski.Core.Entities;
using Microsoft.EntityFrameworkCore;

namespace CSBWebshopSeminarski.Database
{
    public partial class CocoSunBagsWebshopDbContext : DbContext
    {
        public CocoSunBagsWebshopDbContext(DbContextOptions<CocoSunBagsWebshopDbContext> options)
            : base(options)
        {
        }
        public DbSet<Bags> Bags { get; set; }
        public DbSet<BagTypes> BagTypes { get; set; }
        public DbSet<Belts> Belts { get; set; }
        public DbSet<BeltTypes> BeltTypes { get; set; }
        public DbSet<Favorites> Favorites { get; set; }
        public DbSet<OrderItems> OrderItems { get; set; }
        public DbSet<Orders> Orders { get; set; }
        public DbSet<Purchases> Purchases { get; set; }
        public DbSet<Rates> Rates { get; set; }
        public DbSet<Reviews> Reviews { get; set; }
        public DbSet<Roles> Roles { get; set; }
        public DbSet<Transactions> Transactions { get; set; }
        public DbSet<UserRoles> UserRoles { get; set; }
        public DbSet<Users> Users { get; set; }
        public DbSet<Participants> Participants { get; set; }
        public DbSet<Giveaways> Giveaways { get; set; }
        public DbSet<Subscribers> Subscribers { get; set; }
        public DbSet<TrackingEvents> TrackingEvents { get; set; }
        public DbSet<AnnouncementAudit> AnnouncementAudits { get; set; }
        public DbSet<LookbookItems> LookbookItems { get; set; }
        public DbSet<NewsItem> News { get; set; }
        public DbSet<OutfitIdeas> OutfitIdeas { get; set; }
        public DbSet<OutfitIdeaImages> OutfitIdeaImages { get; set; }
        public DbSet<Notifications> Notifications { get; set; }
        public DbSet<PasswordResetTokens> PasswordResetTokens { get; set; }

        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            modelBuilder.Entity<Favorites>(entity =>
            {
                entity.HasKey(f => f.FavoriteID);

                entity.Property(f => f.BagID).IsRequired(false);
                entity.Property(f => f.BeltID).IsRequired(false);

                entity.HasOne(f => f.User)
                    .WithMany()
                    .HasForeignKey(f => f.UserID)
                    .OnDelete(DeleteBehavior.Cascade);

                entity.HasOne(f => f.Bag)
                    .WithMany(b => b.Favorites)
                    .HasForeignKey(f => f.BagID)
                    .OnDelete(DeleteBehavior.Cascade);

                entity.HasOne(f => f.Belt)
                    .WithMany(b => b.Favorites)
                    .HasForeignKey(f => f.BeltID)
                    .OnDelete(DeleteBehavior.Cascade);
            });

            modelBuilder.Entity<Belts>(entity =>
            {
                entity.HasOne(b => b.User)
                    .WithMany()
                    .HasForeignKey(b => b.UserID)
                    .OnDelete(DeleteBehavior.Restrict);
            });

            modelBuilder.Entity<Purchases>(entity =>
            {
                entity.HasOne(p => p.Order)
                    .WithMany()
                    .HasForeignKey(p => p.OrderID)
                    .OnDelete(DeleteBehavior.Cascade);

                entity.HasOne(p => p.User)
                    .WithMany()
                    .HasForeignKey(p => p.UserID)
                    .OnDelete(DeleteBehavior.Restrict);
            });

            modelBuilder.Entity<Transactions>(entity =>
            {
                entity.HasOne(t => t.Order)
                    .WithMany()
                    .HasForeignKey(t => t.OrderID)
                    .OnDelete(DeleteBehavior.Cascade);

                entity.HasOne(t => t.User)
                    .WithMany()
                    .HasForeignKey(t => t.UserID)
                    .OnDelete(DeleteBehavior.Restrict);
            });

            modelBuilder.Entity<NewsItem>()
                .Property(n => n.Price)
                .HasPrecision(18, 2);

            modelBuilder.Entity<Participants>()
                .HasOne(p => p.Giveaway)
                .WithMany(g => g.Participants)
                .HasForeignKey(p => p.GiveawayId)
                .OnDelete(DeleteBehavior.Cascade);

            modelBuilder.Entity<Giveaways>()
                .HasOne(g => g.WinnerParticipant)
                .WithMany()
                .HasForeignKey(g => g.WinnerParticipantId)
                .OnDelete(DeleteBehavior.Restrict);

            modelBuilder.Entity<Participants>()
                .HasIndex(p => new { p.GiveawayId, p.Email })
                .IsUnique();

            modelBuilder.Entity<Giveaways>()
                .Property(g => g.RowVersion)
                .IsRowVersion();

            modelBuilder.Entity<LookbookItems>()
                .HasOne(li => li.Bag)
                .WithMany()
                .HasForeignKey(li => li.BagID)
                .OnDelete(DeleteBehavior.SetNull);

            modelBuilder.Entity<LookbookItems>()
                .HasOne(li => li.Belt)
                .WithMany()
                .HasForeignKey(li => li.BeltID)
                .OnDelete(DeleteBehavior.SetNull);

            // OutfitIdeas configuration
            modelBuilder.Entity<OutfitIdeas>(entity =>
            {
                entity.HasKey(o => o.OutfitIdeaID);

                entity.HasOne(o => o.Bag)
                    .WithMany()
                    .HasForeignKey(o => o.BagID)
                    .IsRequired(false)
                    .OnDelete(DeleteBehavior.Cascade);

                entity.HasOne(o => o.Belt)
                    .WithMany()
                    .HasForeignKey(o => o.BeltID)
                    .IsRequired(false)
                    .OnDelete(DeleteBehavior.Cascade);

                entity.HasOne(o => o.User)
                    .WithMany()
                    .HasForeignKey(o => o.UserID)
                    .OnDelete(DeleteBehavior.Cascade);

                entity.HasMany(o => o.Images)
                    .WithOne(i => i.OutfitIdea)
                    .HasForeignKey(i => i.OutfitIdeaID)
                    .OnDelete(DeleteBehavior.Cascade);
            });

            modelBuilder.Entity<OutfitIdeaImages>(entity =>
            {
                entity.HasKey(i => i.OutfitIdeaImageID);
            });

            modelBuilder.Entity<Orders>().Property(o => o.ShippingStatus).HasConversion<int>();

            modelBuilder.Entity<OrderItems>(entity =>
            {
                entity.HasOne(oi => oi.Bag)
                    .WithMany()
                    .HasForeignKey(oi => oi.BagID)
                    .IsRequired(false)
                    .OnDelete(DeleteBehavior.Cascade);

                entity.HasOne(oi => oi.Belt)
                    .WithMany()
                    .HasForeignKey(oi => oi.BeltID)
                    .IsRequired(false)
                    .OnDelete(DeleteBehavior.Cascade);
            });

            // Reviews: nullable BagID/BeltID with check constraint
            modelBuilder.Entity<Reviews>(entity =>
            {
                entity.Property(r => r.BagID).IsRequired(false);
                entity.Property(r => r.BeltID).IsRequired(false);

                entity.HasOne(r => r.Bag)
                    .WithMany(b => b.Reviews)
                    .HasForeignKey(r => r.BagID)
                    .IsRequired(false)
                    .OnDelete(DeleteBehavior.Cascade);

                entity.HasOne(r => r.Belt)
                    .WithMany(b => b.Reviews)
                    .HasForeignKey(r => r.BeltID)
                    .IsRequired(false)
                    .OnDelete(DeleteBehavior.Cascade);

                entity.ToTable(t => t.HasCheckConstraint("CK_Reviews_OneProduct",
                    "(BagID IS NOT NULL AND BeltID IS NULL) OR (BagID IS NULL AND BeltID IS NOT NULL)"));
            });

            // Rates: nullable BagID/BeltID with check constraint
            modelBuilder.Entity<Rates>(entity =>
            {
                entity.Property(r => r.BagID).IsRequired(false);
                entity.Property(r => r.BeltID).IsRequired(false);

                entity.HasOne(r => r.Bag)
                    .WithMany(b => b.Rate)
                    .HasForeignKey(r => r.BagID)
                    .IsRequired(false)
                    .OnDelete(DeleteBehavior.Cascade);

                entity.HasOne(r => r.Belt)
                    .WithMany(b => b.Rates)
                    .HasForeignKey(r => r.BeltID)
                    .IsRequired(false)
                    .OnDelete(DeleteBehavior.Cascade);

                entity.ToTable(t => t.HasCheckConstraint("CK_Rates_OneProduct",
                    "(BagID IS NOT NULL AND BeltID IS NULL) OR (BagID IS NULL AND BeltID IS NOT NULL)"));
            });

            // Favorites: check constraint and unique indexes (Stavka 18)
            modelBuilder.Entity<Favorites>(entity =>
            {
                entity.HasIndex(f => new { f.UserID, f.BagID })
                    .IsUnique()
                    .HasFilter("BagID IS NOT NULL")
                    .HasDatabaseName("IX_Favorites_UserID_BagID");

                entity.HasIndex(f => new { f.UserID, f.BeltID })
                    .IsUnique()
                    .HasFilter("BeltID IS NOT NULL")
                    .HasDatabaseName("IX_Favorites_UserID_BeltID");

                entity.ToTable(t => t.HasCheckConstraint("CK_Favorites_OneProduct",
                    "(BagID IS NOT NULL AND BeltID IS NULL) OR (BagID IS NULL AND BeltID IS NOT NULL)"));
            });

            // Users: unique indexes (Stavka 19)
            modelBuilder.Entity<Users>(entity =>
            {
                entity.Property(u => u.UserName).HasMaxLength(256);
                entity.Property(u => u.Email).HasMaxLength(256);
                entity.HasIndex(u => u.UserName).IsUnique().HasDatabaseName("IX_Users_UserName");
                entity.HasIndex(u => u.Email).IsUnique().HasDatabaseName("IX_Users_Email");
            });

            // Orders: unique index on OrderNumber; cancellation audit fields
            modelBuilder.Entity<Orders>(entity =>
            {
                entity.Property(o => o.OrderNumber).HasMaxLength(64);
                entity.Property(o => o.CancellationReason).HasMaxLength(500);
                entity.HasIndex(o => o.OrderNumber).IsUnique().HasDatabaseName("IX_Orders_OrderNumber");

                entity.HasOne(o => o.CancelledByUser)
                    .WithMany()
                    .HasForeignKey(o => o.CancelledByUserId)
                    .IsRequired(false)
                    .OnDelete(DeleteBehavior.Restrict);
            });

            // Purchases: one purchase per order; unique StripeId
            modelBuilder.Entity<Purchases>(entity =>
            {
                entity.Property(p => p.StripeId).HasMaxLength(255);
                entity.HasIndex(p => p.StripeId).IsUnique().HasDatabaseName("IX_Purchases_StripeId");
                entity.HasIndex(p => p.OrderID).IsUnique().HasDatabaseName("IX_Purchases_OrderID");
            });

            // Decimal precision for money fields
            modelBuilder.Entity<Orders>().Property(o => o.Price).HasColumnType("decimal(18,2)");
            modelBuilder.Entity<Bags>().Property(b => b.Price).HasColumnType("decimal(18,2)");
            modelBuilder.Entity<Belts>().Property(b => b.Price).HasColumnType("decimal(18,2)");
            modelBuilder.Entity<Purchases>().Property(p => p.Price).HasColumnType("decimal(18,2)");
            modelBuilder.Entity<Transactions>().Property(t => t.Price).HasColumnType("decimal(18,2)");
            modelBuilder.Entity<OrderItems>().Property(oi => oi.Price).HasColumnType("decimal(18,2)");

            modelBuilder.Entity<Notifications>(entity =>
            {
                entity.HasKey(n => n.NotificationID);
                entity.Property(n => n.Type).HasMaxLength(64).IsRequired();
                entity.Property(n => n.Title).HasMaxLength(200).IsRequired();
                entity.Property(n => n.Message).HasMaxLength(1000).IsRequired();
                entity.HasIndex(n => new { n.UserID, n.IsRead }).HasDatabaseName("IX_Notifications_UserID_IsRead");
                entity.HasOne(n => n.User)
                    .WithMany()
                    .HasForeignKey(n => n.UserID)
                    .OnDelete(DeleteBehavior.Cascade);
            });
        }
    }
}
