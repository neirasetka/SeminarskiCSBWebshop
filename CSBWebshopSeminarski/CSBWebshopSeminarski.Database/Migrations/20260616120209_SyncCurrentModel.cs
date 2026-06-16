using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace CSBWebshopSeminarski.Database.Migrations
{
    /// <inheritdoc />
    public partial class SyncCurrentModel : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropIndex(
                name: "IX_Favorites_UserID",
                table: "Favorites");

            migrationBuilder.DropIndex(
                name: "IX_Favorites_UserID_BagID",
                table: "Favorites");

            migrationBuilder.DropIndex(
                name: "IX_Favorites_UserID_BeltID",
                table: "Favorites");

            migrationBuilder.AlterColumn<string>(
                name: "StripePaymentIntentId",
                table: "Orders",
                type: "nvarchar(max)",
                nullable: true,
                oldClrType: typeof(string),
                oldType: "nvarchar(255)",
                oldNullable: true);

            migrationBuilder.AlterColumn<string>(
                name: "StripeCheckoutSessionId",
                table: "Orders",
                type: "nvarchar(max)",
                nullable: true,
                oldClrType: typeof(string),
                oldType: "nvarchar(255)",
                oldNullable: true);

            migrationBuilder.CreateIndex(
                name: "IX_Favorites_UserID_BagID",
                table: "Favorites",
                columns: new[] { "UserID", "BagID" },
                unique: true,
                filter: "BagID IS NOT NULL");

            migrationBuilder.CreateIndex(
                name: "IX_Favorites_UserID_BeltID",
                table: "Favorites",
                columns: new[] { "UserID", "BeltID" },
                unique: true,
                filter: "BeltID IS NOT NULL");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropIndex(
                name: "IX_Favorites_UserID_BagID",
                table: "Favorites");

            migrationBuilder.DropIndex(
                name: "IX_Favorites_UserID_BeltID",
                table: "Favorites");

            migrationBuilder.AlterColumn<string>(
                name: "StripePaymentIntentId",
                table: "Orders",
                type: "nvarchar(255)",
                nullable: true,
                oldClrType: typeof(string),
                oldType: "nvarchar(max)",
                oldNullable: true);

            migrationBuilder.AlterColumn<string>(
                name: "StripeCheckoutSessionId",
                table: "Orders",
                type: "nvarchar(255)",
                nullable: true,
                oldClrType: typeof(string),
                oldType: "nvarchar(max)",
                oldNullable: true);

            migrationBuilder.CreateIndex(
                name: "IX_Favorites_UserID",
                table: "Favorites",
                column: "UserID");

            migrationBuilder.CreateIndex(
                name: "IX_Favorites_UserID_BagID",
                table: "Favorites",
                columns: new[] { "UserID", "BagID" },
                unique: true,
                filter: "[BagID] IS NOT NULL");

            migrationBuilder.CreateIndex(
                name: "IX_Favorites_UserID_BeltID",
                table: "Favorites",
                columns: new[] { "UserID", "BeltID" },
                unique: true,
                filter: "[BeltID] IS NOT NULL");
        }
    }
}
