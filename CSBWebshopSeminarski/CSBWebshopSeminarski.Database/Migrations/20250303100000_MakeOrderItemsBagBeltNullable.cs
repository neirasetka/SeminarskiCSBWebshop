using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace CSBWebshopSeminarski.Database.Migrations
{
    /// <inheritdoc />
    public partial class MakeOrderItemsBagBeltNullable : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_OrderItems_Bags_BagID",
                table: "OrderItems");

            migrationBuilder.DropForeignKey(
                name: "FK_OrderItems_Belts_BeltID",
                table: "OrderItems");

            migrationBuilder.AlterColumn<int>(
                name: "BagID",
                table: "OrderItems",
                type: "int",
                nullable: true,
                oldClrType: typeof(int),
                oldType: "int");

            migrationBuilder.AlterColumn<int>(
                name: "BeltID",
                table: "OrderItems",
                type: "int",
                nullable: true,
                oldClrType: typeof(int),
                oldType: "int");

            migrationBuilder.AddForeignKey(
                name: "FK_OrderItems_Bags_BagID",
                table: "OrderItems",
                column: "BagID",
                principalTable: "Bags",
                principalColumn: "BagID",
                onDelete: ReferentialAction.Cascade);

            migrationBuilder.AddForeignKey(
                name: "FK_OrderItems_Belts_BeltID",
                table: "OrderItems",
                column: "BeltID",
                principalTable: "Belts",
                principalColumn: "BeltID",
                onDelete: ReferentialAction.Cascade);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_OrderItems_Bags_BagID",
                table: "OrderItems");

            migrationBuilder.DropForeignKey(
                name: "FK_OrderItems_Belts_BeltID",
                table: "OrderItems");

            migrationBuilder.AlterColumn<int>(
                name: "BagID",
                table: "OrderItems",
                type: "int",
                nullable: false,
                oldClrType: typeof(int),
                oldType: "int",
                oldNullable: true);

            migrationBuilder.AlterColumn<int>(
                name: "BeltID",
                table: "OrderItems",
                type: "int",
                nullable: false,
                oldClrType: typeof(int),
                oldType: "int",
                oldNullable: true);

            migrationBuilder.AddForeignKey(
                name: "FK_OrderItems_Bags_BagID",
                table: "OrderItems",
                column: "BagID",
                principalTable: "Bags",
                principalColumn: "BagID",
                onDelete: ReferentialAction.Cascade);

            migrationBuilder.AddForeignKey(
                name: "FK_OrderItems_Belts_BeltID",
                table: "OrderItems",
                column: "BeltID",
                principalTable: "Belts",
                principalColumn: "BeltID",
                onDelete: ReferentialAction.Cascade);
        }
    }
}
