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

        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            modelBuilder.Entity<Favorites>(entity =>
            {
                entity.HasKey(f => f.FavoriteID);

                // Ensure optional FKs for product references
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

            // Prevent multiple cascade paths: deleting a User should not cascade delete Belts
            // so that there is only one cascade path to Favorites (directly from User -> Favorites).
            modelBuilder.Entity<Belts>(entity =>
            {
                entity.HasOne(b => b.User)
                    .WithMany()
                    .HasForeignKey(b => b.UserID)
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

            // Configure Purchases relationships to avoid multiple cascade paths
            // Keep cascade from Orders -> Purchases, but restrict delete from Users -> Purchases
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

            // Configure Transactions similarly: cascade from Orders, restrict from Users
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
        }
    }
}
