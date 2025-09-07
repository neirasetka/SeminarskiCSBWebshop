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
            migrationBuilder.DropForeignKey(
                name: "FK_Belts_Users_UserID",
                table: "Belts");

            migrationBuilder.DropForeignKey(
                name: "FK_Favorites_Users_UserID1",
                table: "Favorites");

            migrationBuilder.DropPrimaryKey(
                name: "PK_Favorites",
                table: "Favorites");

            migrationBuilder.DropIndex(
                name: "IX_Favorites_UserID1",
                table: "Favorites");

            migrationBuilder.RenameColumn(
                name: "UserID1",
                table: "Favorites",
                newName: "FavoriteID");

            migrationBuilder.AlterColumn<int>(
                name: "BeltID",
                table: "Favorites",
                type: "int",
                nullable: true,
                oldClrType: typeof(int),
                oldType: "int");

            migrationBuilder.AlterColumn<int>(
                name: "BagID",
                table: "Favorites",
                type: "int",
                nullable: true,
                oldClrType: typeof(int),
                oldType: "int");

            migrationBuilder.AlterColumn<int>(
                name: "UserID",
                table: "Favorites",
                type: "int",
                nullable: false,
                oldClrType: typeof(int),
                oldType: "int")
                .OldAnnotation("SqlServer:Identity", "1, 1");

            migrationBuilder.AlterColumn<int>(
                name: "FavoriteID",
                table: "Favorites",
                type: "int",
                nullable: false,
                oldClrType: typeof(int),
                oldType: "int")
                .Annotation("SqlServer:Identity", "1, 1");

            migrationBuilder.AddPrimaryKey(
                name: "PK_Favorites",
                table: "Favorites",
                column: "FavoriteID");

            migrationBuilder.CreateIndex(
                name: "IX_Favorites_UserID",
                table: "Favorites",
                column: "UserID");

            migrationBuilder.AddForeignKey(
                name: "FK_Belts_Users_UserID",
                table: "Belts",
                column: "UserID",
                principalTable: "Users",
                principalColumn: "UserID",
                onDelete: ReferentialAction.Restrict);

            migrationBuilder.AddForeignKey(
                name: "FK_Favorites_Users_UserID",
                table: "Favorites",
                column: "UserID",
                principalTable: "Users",
                principalColumn: "UserID",
                onDelete: ReferentialAction.Cascade);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_Belts_Users_UserID",
                table: "Belts");

            migrationBuilder.DropForeignKey(
                name: "FK_Favorites_Users_UserID",
                table: "Favorites");

            migrationBuilder.DropPrimaryKey(
                name: "PK_Favorites",
                table: "Favorites");

            migrationBuilder.DropIndex(
                name: "IX_Favorites_UserID",
                table: "Favorites");

            migrationBuilder.RenameColumn(
                name: "FavoriteID",
                table: "Favorites",
                newName: "UserID1");

            migrationBuilder.AlterColumn<int>(
                name: "UserID",
                table: "Favorites",
                type: "int",
                nullable: false,
                oldClrType: typeof(int),
                oldType: "int")
                .Annotation("SqlServer:Identity", "1, 1");

            migrationBuilder.AlterColumn<int>(
                name: "BeltID",
                table: "Favorites",
                type: "int",
                nullable: false,
                defaultValue: 0,
                oldClrType: typeof(int),
                oldType: "int",
                oldNullable: true);

            migrationBuilder.AlterColumn<int>(
                name: "BagID",
                table: "Favorites",
                type: "int",
                nullable: false,
                defaultValue: 0,
                oldClrType: typeof(int),
                oldType: "int",
                oldNullable: true);

            migrationBuilder.AlterColumn<int>(
                name: "UserID1",
                table: "Favorites",
                type: "int",
                nullable: false,
                oldClrType: typeof(int),
                oldType: "int")
                .OldAnnotation("SqlServer:Identity", "1, 1");

            migrationBuilder.AddPrimaryKey(
                name: "PK_Favorites",
                table: "Favorites",
                column: "UserID");

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

            migrationBuilder.AddForeignKey(
                name: "FK_Favorites_Users_UserID1",
                table: "Favorites",
                column: "UserID1",
                principalTable: "Users",
                principalColumn: "UserID",
                onDelete: ReferentialAction.Cascade);
        }
    }
}
