using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace CSBWebshopSeminarski.Database.Migrations
{
    /// <inheritdoc />
    public partial class PendingModelChanges : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            // Drop Favorites -> Users FK if it exists under any of the possible names, scoped to Favorites table
            migrationBuilder.Sql("IF EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_Favorites_Users_UserID' AND parent_object_id = OBJECT_ID(N'[dbo].[Favorites]')) ALTER TABLE [Favorites] DROP CONSTRAINT [FK_Favorites_Users_UserID];");
            migrationBuilder.Sql("IF EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_Favorites_Users_UserID1' AND parent_object_id = OBJECT_ID(N'[dbo].[Favorites]')) ALTER TABLE [Favorites] DROP CONSTRAINT [FK_Favorites_Users_UserID1];");
            migrationBuilder.Sql("IF EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_Favorites_new_Users_UserID' AND parent_object_id = OBJECT_ID(N'[dbo].[Favorites]')) ALTER TABLE [Favorites] DROP CONSTRAINT [FK_Favorites_new_Users_UserID];");

            migrationBuilder.DropForeignKey(
                name: "FK_Purchases_Users_UserID",
                table: "Purchases");

            migrationBuilder.AddForeignKey(
                name: "FK_Favorites_Users_UserID",
                table: "Favorites",
                column: "UserID",
                principalTable: "Users",
                principalColumn: "UserID",
                onDelete: ReferentialAction.Cascade);

            migrationBuilder.AddForeignKey(
                name: "FK_Purchases_Users_UserID",
                table: "Purchases",
                column: "UserID",
                principalTable: "Users",
                principalColumn: "UserID",
                onDelete: ReferentialAction.Restrict);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            // Drop Favorites -> Users FK if it exists under any of the possible names, scoped to Favorites table
            migrationBuilder.Sql("IF EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_Favorites_Users_UserID' AND parent_object_id = OBJECT_ID(N'[dbo].[Favorites]')) ALTER TABLE [Favorites] DROP CONSTRAINT [FK_Favorites_Users_UserID];");
            migrationBuilder.Sql("IF EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_Favorites_Users_UserID1' AND parent_object_id = OBJECT_ID(N'[dbo].[Favorites]')) ALTER TABLE [Favorites] DROP CONSTRAINT [FK_Favorites_Users_UserID1];");
            migrationBuilder.Sql("IF EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_Favorites_new_Users_UserID' AND parent_object_id = OBJECT_ID(N'[dbo].[Favorites]')) ALTER TABLE [Favorites] DROP CONSTRAINT [FK_Favorites_new_Users_UserID];");

            migrationBuilder.DropForeignKey(
                name: "FK_Purchases_Users_UserID",
                table: "Purchases");

            migrationBuilder.AddForeignKey(
                name: "FK_Favorites_Users_UserID",
                table: "Favorites",
                column: "UserID",
                principalTable: "Users",
                principalColumn: "UserID",
                onDelete: ReferentialAction.Restrict);

            migrationBuilder.AddForeignKey(
                name: "FK_Purchases_Users_UserID",
                table: "Purchases",
                column: "UserID",
                principalTable: "Users",
                principalColumn: "UserID",
                onDelete: ReferentialAction.Cascade);
        }
    }
}
