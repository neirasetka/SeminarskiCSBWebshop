using CSBWebshopSeminarski.Database;
using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace CSBWebshopSeminarski.Database.Migrations
{
    /// <summary>
    /// Repairs databases created from an older <c>newDatabase</c> script where <c>OutfitIdeas</c>
    /// had no <c>BeltID</c> column. Skips work when the column already exists (fresh installs after the fix).
    /// </summary>
    [DbContext(typeof(CocoSunBagsWebshopDbContext))]
    [Migration("20260414120000_AddOutfitIdeasBeltIdForLegacyDatabase")]
    public partial class AddOutfitIdeasBeltIdForLegacyDatabase : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.Sql(@"
IF COL_LENGTH(N'dbo.OutfitIdeas', N'BeltID') IS NULL
BEGIN
    ALTER TABLE [dbo].[OutfitIdeas] DROP CONSTRAINT [FK_OutfitIdeas_Bags_BagID];
    ALTER TABLE [dbo].[OutfitIdeas] ALTER COLUMN [BagID] INT NULL;
    ALTER TABLE [dbo].[OutfitIdeas] ADD [BeltID] INT NULL;
    IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_OutfitIdeas_BeltID' AND object_id = OBJECT_ID(N'dbo.OutfitIdeas'))
        CREATE INDEX [IX_OutfitIdeas_BeltID] ON [dbo].[OutfitIdeas] ([BeltID]);
    ALTER TABLE [dbo].[OutfitIdeas] WITH CHECK ADD CONSTRAINT [FK_OutfitIdeas_Bags_BagID]
        FOREIGN KEY ([BagID]) REFERENCES [dbo].[Bags] ([BagID]) ON DELETE CASCADE;
    ALTER TABLE [dbo].[OutfitIdeas] WITH CHECK ADD CONSTRAINT [FK_OutfitIdeas_Belts_BeltID]
        FOREIGN KEY ([BeltID]) REFERENCES [dbo].[Belts] ([BeltID]) ON DELETE CASCADE;
END
");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
        }
    }
}
