using CSBWebshopSeminarski.Database;
using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace CSBWebshopSeminarski.Database.Migrations
{
    [DbContext(typeof(CocoSunBagsWebshopDbContext))]
    [Migration("20260414160000_AddPaymentConfirmationEmailSentToOrders")]
    public partial class AddPaymentConfirmationEmailSentToOrders : Migration
    {
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<bool>(
                name: "PaymentConfirmationEmailSent",
                table: "Orders",
                type: "bit",
                nullable: false,
                defaultValue: false);
        }

        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "PaymentConfirmationEmailSent",
                table: "Orders");
        }
    }
}
