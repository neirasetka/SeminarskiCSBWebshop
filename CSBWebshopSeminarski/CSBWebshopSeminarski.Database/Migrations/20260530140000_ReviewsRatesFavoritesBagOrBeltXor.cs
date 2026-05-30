using CSBWebshopSeminarski.Database;
using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace CSBWebshopSeminarski.Database.Migrations
{
    [DbContext(typeof(CocoSunBagsWebshopDbContext))]
    [Migration("20260530140000_ReviewsRatesFavoritesBagOrBeltXor")]
    public partial class ReviewsRatesFavoritesBagOrBeltXor : Migration
    {
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.Sql(ProductBagBeltSchemaCompatibility.EnsureReviewsRatesFavoritesBagOrBeltXorSql);
        }

        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropCheckConstraint(
                name: "CK_Favorites_OneProduct",
                table: "Favorites");

            migrationBuilder.DropCheckConstraint(
                name: "CK_Rates_OneProduct",
                table: "Rates");

            migrationBuilder.DropCheckConstraint(
                name: "CK_Reviews_OneProduct",
                table: "Reviews");

            migrationBuilder.DropIndex(
                name: "IX_Favorites_UserID_BeltID",
                table: "Favorites");

            migrationBuilder.DropIndex(
                name: "IX_Favorites_UserID_BagID",
                table: "Favorites");
        }
    }
}
