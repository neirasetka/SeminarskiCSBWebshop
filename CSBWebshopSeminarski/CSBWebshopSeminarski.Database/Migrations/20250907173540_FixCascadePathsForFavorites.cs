using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace CSBWebshopSeminarski.Database.Migrations
{
    /// <inheritdoc />
    public partial class FixCascadePathsForFavorites : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            // Ensure Belts -> Users delete behavior is Restrict
            migrationBuilder.DropForeignKey(
                name: "FK_Belts_Users_UserID",
                table: "Belts");

            // Build a new Favorites table with the desired schema (avoids altering IDENTITY)
            migrationBuilder.CreateTable(
                name: "Favorites_new",
                columns: table => new
                {
                    FavoriteID = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    UserID = table.Column<int>(type: "int", nullable: false),
                    BagID = table.Column<int>(type: "int", nullable: true),
                    BeltID = table.Column<int>(type: "int", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Favorites_new", x => x.FavoriteID);
                    table.ForeignKey(
                        name: "FK_Favorites_new_Bags_BagID",
                        column: x => x.BagID,
                        principalTable: "Bags",
                        principalColumn: "BagID",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_Favorites_new_Belts_BeltID",
                        column: x => x.BeltID,
                        principalTable: "Belts",
                        principalColumn: "BeltID",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_Favorites_new_Users_UserID",
                        column: x => x.UserID,
                        principalTable: "Users",
                        principalColumn: "UserID",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "IX_Favorites_new_BagID",
                table: "Favorites_new",
                column: "BagID");

            migrationBuilder.CreateIndex(
                name: "IX_Favorites_new_BeltID",
                table: "Favorites_new",
                column: "BeltID");

            migrationBuilder.CreateIndex(
                name: "IX_Favorites_new_UserID",
                table: "Favorites_new",
                column: "UserID");

            // Migrate data from old Favorites table to the new schema
            migrationBuilder.Sql(
                "INSERT INTO [Favorites_new] ([UserID], [BagID], [BeltID]) SELECT [UserID1], [BagID], [BeltID] FROM [Favorites];");

            // Drop the old Favorites table (removes old FKs and PK)
            migrationBuilder.DropTable(
                name: "Favorites");

            // Rename the new table to Favorites
            migrationBuilder.RenameTable(
                name: "Favorites_new",
                newName: "Favorites");

            // Re-add Belts -> Users with Restrict
            migrationBuilder.AddForeignKey(
                name: "FK_Belts_Users_UserID",
                table: "Belts",
                column: "UserID",
                principalTable: "Users",
                principalColumn: "UserID",
                onDelete: ReferentialAction.Restrict);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            // Revert Belts -> Users to Cascade
            migrationBuilder.DropForeignKey(
                name: "FK_Belts_Users_UserID",
                table: "Belts");

            // Drop the new Favorites table and recreate the original schema
            migrationBuilder.DropTable(
                name: "Favorites");

            migrationBuilder.CreateTable(
                name: "Favorites",
                columns: table => new
                {
                    UserID = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    UserID1 = table.Column<int>(type: "int", nullable: false),
                    BagID = table.Column<int>(type: "int", nullable: false),
                    BeltID = table.Column<int>(type: "int", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Favorites", x => x.UserID);
                    table.ForeignKey(
                        name: "FK_Favorites_Bags_BagID",
                        column: x => x.BagID,
                        principalTable: "Bags",
                        principalColumn: "BagID",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_Favorites_Belts_BeltID",
                        column: x => x.BeltID,
                        principalTable: "Belts",
                        principalColumn: "BeltID",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_Favorites_Users_UserID1",
                        column: x => x.UserID1,
                        principalTable: "Users",
                        principalColumn: "UserID",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "IX_Favorites_BagID",
                table: "Favorites",
                column: "BagID");

            migrationBuilder.CreateIndex(
                name: "IX_Favorites_BeltID",
                table: "Favorites",
                column: "BeltID");

            migrationBuilder.CreateIndex(
                name: "IX_Favorites_UserID1",
                table: "Favorites",
                column: "UserID1");

            migrationBuilder.AddForeignKey(
                name: "FK_Belts_Users_UserID",
                table: "Belts",
                column: "UserID",
                principalTable: "Users",
                principalColumn: "UserID",
                onDelete: ReferentialAction.Cascade);
        }
    }
}
