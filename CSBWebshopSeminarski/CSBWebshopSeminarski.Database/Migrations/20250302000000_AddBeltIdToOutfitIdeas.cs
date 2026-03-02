using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace CSBWebshopSeminarski.Database.Migrations
{
    /// <inheritdoc />
    public partial class AddBeltIdToOutfitIdeas : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_OutfitIdeas_Bags_BagID",
                table: "OutfitIdeas");

            migrationBuilder.AlterColumn<int>(
                name: "BagID",
                table: "OutfitIdeas",
                type: "int",
                nullable: true,
                oldClrType: typeof(int),
                oldType: "int");

            migrationBuilder.AddColumn<int>(
                name: "BeltID",
                table: "OutfitIdeas",
                type: "int",
                nullable: true);

            migrationBuilder.CreateIndex(
                name: "IX_OutfitIdeas_BeltID",
                table: "OutfitIdeas",
                column: "BeltID");

            migrationBuilder.AddForeignKey(
                name: "FK_OutfitIdeas_Bags_BagID",
                table: "OutfitIdeas",
                column: "BagID",
                principalTable: "Bags",
                principalColumn: "BagID",
                onDelete: ReferentialAction.Cascade);

            migrationBuilder.AddForeignKey(
                name: "FK_OutfitIdeas_Belts_BeltID",
                table: "OutfitIdeas",
                column: "BeltID",
                principalTable: "Belts",
                principalColumn: "BeltID",
                onDelete: ReferentialAction.Cascade);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_OutfitIdeas_Bags_BagID",
                table: "OutfitIdeas");

            migrationBuilder.DropForeignKey(
                name: "FK_OutfitIdeas_Belts_BeltID",
                table: "OutfitIdeas");

            migrationBuilder.DropIndex(
                name: "IX_OutfitIdeas_BeltID",
                table: "OutfitIdeas");

            migrationBuilder.DropColumn(
                name: "BeltID",
                table: "OutfitIdeas");

            migrationBuilder.AlterColumn<int>(
                name: "BagID",
                table: "OutfitIdeas",
                type: "int",
                nullable: false,
                oldClrType: typeof(int),
                oldType: "int",
                oldNullable: true);

            migrationBuilder.AddForeignKey(
                name: "FK_OutfitIdeas_Bags_BagID",
                table: "OutfitIdeas",
                column: "BagID",
                principalTable: "Bags",
                principalColumn: "BagID",
                onDelete: ReferentialAction.Cascade);
        }
    }
}
