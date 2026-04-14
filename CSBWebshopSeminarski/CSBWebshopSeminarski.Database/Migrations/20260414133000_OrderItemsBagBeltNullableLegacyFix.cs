using CSBWebshopSeminarski.Database;
using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace CSBWebshopSeminarski.Database.Migrations
{
    /// <summary>
    /// Legacy databases (and the baseline <c>newDatabase</c> migration) define <c>OrderItems.BagID</c>
    /// and <c>BeltID</c> as NOT NULL. Cart lines are either a bag or a belt, so one column must be NULL.
    /// This aligns the table with the EF entity and fixes INSERT failures for belt-only cart lines.
    /// </summary>
    [DbContext(typeof(CocoSunBagsWebshopDbContext))]
    [Migration("20260414133000_OrderItemsBagBeltNullableLegacyFix")]
    public partial class OrderItemsBagBeltNullableLegacyFix : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.Sql(OrderItemsSchemaCompatibility.EnsureOrderItemsBagOrBeltColumnsNullableSql);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
        }
    }
}
