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

        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
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
        }
    }
}
