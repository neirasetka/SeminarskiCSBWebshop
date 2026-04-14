using CSBWebshopSeminarski.Database;
using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace CSBWebshopSeminarski.Database.Migrations
{
    /// <summary>
    /// Legacy databases (and the baseline <c>newDatabase</c> migration) define <c>OrderItems.BagID</c>
    /// and <c>BeltID</c> as NOT NULL. Cart lines are either a bag or a belt, so one column must be NULL.
    /// This aligns the table with the EF entity and fixes INSERT failures for belt-only cart lines.
    /// </summary>
    [DbContext(typeof(CocoSunBagsWebshopDbContext))]
    [Migration("20260414133000_OrderItemsBagBeltNullableLegacyFix")]
    public partial class OrderItemsBagBeltNullableLegacyFix : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.Sql(@"
IF OBJECT_ID(N'dbo.OrderItems', N'U') IS NULL
    RETURN;

-- Only alter when at least one column is still NOT NULL
IF NOT EXISTS (
    SELECT 1
    FROM sys.columns c
    INNER JOIN sys.tables t ON c.object_id = t.object_id
    INNER JOIN sys.schemas s ON t.schema_id = s.schema_id
    WHERE s.name = N'dbo' AND t.name = N'OrderItems' AND c.name IN (N'BagID', N'BeltID')
      AND c.is_nullable = 0)
    RETURN;

DECLARE @fkBag sysname =
    (SELECT fk.name
     FROM sys.foreign_keys AS fk
     INNER JOIN sys.foreign_key_columns AS fkc ON fk.object_id = fkc.constraint_object_id
     INNER JOIN sys.columns AS col ON fkc.parent_object_id = col.object_id AND fkc.parent_column_id = col.column_id
     WHERE fk.parent_object_id = OBJECT_ID(N'dbo.OrderItems') AND col.name = N'BagID');

DECLARE @fkBelt sysname =
    (SELECT fk.name
     FROM sys.foreign_keys AS fk
     INNER JOIN sys.foreign_key_columns AS fkc ON fk.object_id = fkc.constraint_object_id
     INNER JOIN sys.columns AS col ON fkc.parent_object_id = col.object_id AND fkc.parent_column_id = col.column_id
     WHERE fk.parent_object_id = OBJECT_ID(N'dbo.OrderItems') AND col.name = N'BeltID');

IF @fkBag IS NOT NULL
    EXEC(N'ALTER TABLE [dbo].[OrderItems] DROP CONSTRAINT [' + QUOTENAME(@fkBag) + N']');

IF @fkBelt IS NOT NULL
    EXEC(N'ALTER TABLE [dbo].[OrderItems] DROP CONSTRAINT [' + QUOTENAME(@fkBelt) + N']');

ALTER TABLE [dbo].[OrderItems] ALTER COLUMN [BagID] INT NULL;
ALTER TABLE [dbo].[OrderItems] ALTER COLUMN [BeltID] INT NULL;

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_OrderItems_Bags_BagID')
    ALTER TABLE [dbo].[OrderItems] WITH CHECK ADD CONSTRAINT [FK_OrderItems_Bags_BagID]
        FOREIGN KEY ([BagID]) REFERENCES [dbo].[Bags] ([BagID]) ON DELETE CASCADE;

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_OrderItems_Belts_BeltID')
    ALTER TABLE [dbo].[OrderItems] WITH CHECK ADD CONSTRAINT [FK_OrderItems_Belts_BeltID]
        FOREIGN KEY ([BeltID]) REFERENCES [dbo].[Belts] ([BeltID]) ON DELETE CASCADE;
");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
        }
    }
}
