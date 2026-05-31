using CSBWebshopSeminarski.Database;
using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace CSBWebshopSeminarski.Database.Migrations
{
    [DbContext(typeof(CocoSunBagsWebshopDbContext))]
    [Migration("20260530190000_AddUserSoftDelete")]
    public partial class AddUserSoftDelete : Migration
    {
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<bool>(
                name: "IsDeleted",
                table: "Users",
                type: "bit",
                nullable: false,
                defaultValue: false);

            migrationBuilder.AddColumn<DateTime>(
                name: "DeletedAt",
                table: "Users",
                type: "datetime2",
                nullable: true);
        }

        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(name: "IsDeleted", table: "Users");
            migrationBuilder.DropColumn(name: "DeletedAt", table: "Users");
        }
    }
}
