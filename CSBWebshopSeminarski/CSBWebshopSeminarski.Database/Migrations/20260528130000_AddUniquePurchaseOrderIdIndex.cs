using CSBWebshopSeminarski.Database;
using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace CSBWebshopSeminarski.Database.Migrations
{
    [DbContext(typeof(CocoSunBagsWebshopDbContext))]
    [Migration("20260528130000_AddUniquePurchaseOrderIdIndex")]
    public partial class AddUniquePurchaseOrderIdIndex : Migration
    {
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropIndex(
                name: "IX_Purchases_OrderID",
                table: "Purchases");

            migrationBuilder.CreateIndex(
                name: "IX_Purchases_OrderID",
                table: "Purchases",
                column: "OrderID",
                unique: true);
        }

        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropIndex(
                name: "IX_Purchases_OrderID",
                table: "Purchases");

            migrationBuilder.CreateIndex(
                name: "IX_Purchases_OrderID",
                table: "Purchases",
                column: "OrderID");
        }
    }
}
