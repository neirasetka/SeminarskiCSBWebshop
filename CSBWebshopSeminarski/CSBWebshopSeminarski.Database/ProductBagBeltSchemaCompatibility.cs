namespace CSBWebshopSeminarski.Database;

/// <summary>
/// Idempotent SQL so Reviews, Rates, and Favorites store either a bag or a belt reference (one FK null).
/// </summary>
public static class ProductBagBeltSchemaCompatibility
{
    private const string OneProductCheckSql =
        "(BagID IS NOT NULL AND BeltID IS NULL) OR (BagID IS NULL AND BeltID IS NOT NULL)";

    public static readonly string EnsureReviewsRatesFavoritesBagOrBeltXorSql =
        NormalizeLegacyDataSql
        + MakeColumnsNullableSql("Reviews")
        + MakeColumnsNullableSql("Rates")
        + AddCheckConstraintsSql
        + AddFavoriteIndexesSql;

    private const string NormalizeLegacyDataSql = @"
-- Normalize sentinel zeros and legacy rows that had both FKs set
IF OBJECT_ID(N'dbo.Reviews', N'U') IS NOT NULL
BEGIN
    UPDATE [dbo].[Reviews] SET [BagID] = NULL WHERE [BagID] = 0;
    UPDATE [dbo].[Reviews] SET [BeltID] = NULL WHERE [BeltID] = 0;
    UPDATE [dbo].[Reviews] SET [BeltID] = NULL WHERE [BagID] IS NOT NULL AND [BeltID] IS NOT NULL;
END

IF OBJECT_ID(N'dbo.Rates', N'U') IS NOT NULL
BEGIN
    UPDATE [dbo].[Rates] SET [BagID] = NULL WHERE [BagID] = 0;
    UPDATE [dbo].[Rates] SET [BeltID] = NULL WHERE [BeltID] = 0;
    UPDATE [dbo].[Rates] SET [BeltID] = NULL WHERE [BagID] IS NOT NULL AND [BeltID] IS NOT NULL;
END

IF OBJECT_ID(N'dbo.Favorites', N'U') IS NOT NULL
BEGIN
    UPDATE [dbo].[Favorites] SET [BagID] = NULL WHERE [BagID] = 0;
    UPDATE [dbo].[Favorites] SET [BeltID] = NULL WHERE [BeltID] = 0;
    UPDATE [dbo].[Favorites] SET [BeltID] = NULL WHERE [BagID] IS NOT NULL AND [BeltID] IS NOT NULL;
END
";

    private const string AddCheckConstraintsSql = @"
IF OBJECT_ID(N'dbo.Reviews', N'U') IS NOT NULL
   AND NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = N'CK_Reviews_OneProduct' AND parent_object_id = OBJECT_ID(N'dbo.Reviews'))
    ALTER TABLE [dbo].[Reviews] WITH CHECK ADD CONSTRAINT [CK_Reviews_OneProduct]
        CHECK ((BagID IS NOT NULL AND BeltID IS NULL) OR (BagID IS NULL AND BeltID IS NOT NULL));

IF OBJECT_ID(N'dbo.Rates', N'U') IS NOT NULL
   AND NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = N'CK_Rates_OneProduct' AND parent_object_id = OBJECT_ID(N'dbo.Rates'))
    ALTER TABLE [dbo].[Rates] WITH CHECK ADD CONSTRAINT [CK_Rates_OneProduct]
        CHECK ((BagID IS NOT NULL AND BeltID IS NULL) OR (BagID IS NULL AND BeltID IS NOT NULL));

IF OBJECT_ID(N'dbo.Favorites', N'U') IS NOT NULL
   AND NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = N'CK_Favorites_OneProduct' AND parent_object_id = OBJECT_ID(N'dbo.Favorites'))
    ALTER TABLE [dbo].[Favorites] WITH CHECK ADD CONSTRAINT [CK_Favorites_OneProduct]
        CHECK ((BagID IS NOT NULL AND BeltID IS NULL) OR (BagID IS NULL AND BeltID IS NOT NULL));
";

    private const string AddFavoriteIndexesSql = @"
IF OBJECT_ID(N'dbo.Favorites', N'U') IS NOT NULL
   AND NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_Favorites_UserID_BagID' AND object_id = OBJECT_ID(N'dbo.Favorites'))
    CREATE UNIQUE INDEX [IX_Favorites_UserID_BagID] ON [dbo].[Favorites]([UserID], [BagID]) WHERE [BagID] IS NOT NULL;

IF OBJECT_ID(N'dbo.Favorites', N'U') IS NOT NULL
   AND NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_Favorites_UserID_BeltID' AND object_id = OBJECT_ID(N'dbo.Favorites'))
    CREATE UNIQUE INDEX [IX_Favorites_UserID_BeltID] ON [dbo].[Favorites]([UserID], [BeltID]) WHERE [BeltID] IS NOT NULL;
";

    private static string MakeColumnsNullableSql(string tableName) => $@"
IF OBJECT_ID(N'dbo.{tableName}', N'U') IS NULL
    GOTO Skip_{tableName};

IF NOT EXISTS (
    SELECT 1
    FROM sys.columns c
    INNER JOIN sys.tables t ON c.object_id = t.object_id
    INNER JOIN sys.schemas s ON t.schema_id = s.schema_id
    WHERE s.name = N'dbo' AND t.name = N'{tableName}' AND c.name IN (N'BagID', N'BeltID')
      AND c.is_nullable = 0)
    GOTO ReaddFk_{tableName};

DECLARE @constraintName_{tableName} sysname;
DECLARE @dropSql_{tableName} nvarchar(max);

WHILE 1 = 1
BEGIN
    SELECT TOP (1) @constraintName_{tableName} = fk.name
    FROM sys.foreign_keys AS fk
    INNER JOIN sys.foreign_key_columns AS fkc ON fk.object_id = fkc.constraint_object_id
    INNER JOIN sys.columns AS col ON fkc.parent_object_id = col.object_id AND fkc.parent_column_id = col.column_id
    WHERE fk.parent_object_id = OBJECT_ID(N'dbo.{tableName}')
      AND col.name IN (N'BagID', N'BeltID');
    IF @constraintName_{tableName} IS NULL BREAK;
    SET @dropSql_{tableName} = N'ALTER TABLE [dbo].[{tableName}] DROP CONSTRAINT ' + N'[' + REPLACE(@constraintName_{tableName}, N']', N']]') + N'];';
    EXEC sys.sp_executesql @dropSql_{tableName};
    SET @constraintName_{tableName} = NULL;
END;

WHILE 1 = 1
BEGIN
    SELECT TOP (1) @constraintName_{tableName} = dc.name
    FROM sys.default_constraints AS dc
    INNER JOIN sys.columns AS c ON dc.parent_object_id = c.object_id AND dc.parent_column_id = c.column_id
    WHERE dc.parent_object_id = OBJECT_ID(N'dbo.{tableName}')
      AND c.name IN (N'BagID', N'BeltID');
    IF @constraintName_{tableName} IS NULL BREAK;
    SET @dropSql_{tableName} = N'ALTER TABLE [dbo].[{tableName}] DROP CONSTRAINT ' + N'[' + REPLACE(@constraintName_{tableName}, N']', N']]') + N'];';
    EXEC sys.sp_executesql @dropSql_{tableName};
    SET @constraintName_{tableName} = NULL;
END;

IF COL_LENGTH(N'dbo.{tableName}', N'BagID') IS NOT NULL
    ALTER TABLE [dbo].[{tableName}] ALTER COLUMN [BagID] INT NULL;

IF COL_LENGTH(N'dbo.{tableName}', N'BeltID') IS NOT NULL
    ALTER TABLE [dbo].[{tableName}] ALTER COLUMN [BeltID] INT NULL;

ReaddFk_{tableName}:
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_{tableName}_Bags_BagID' AND parent_object_id = OBJECT_ID(N'dbo.{tableName}'))
    ALTER TABLE [dbo].[{tableName}] WITH CHECK ADD CONSTRAINT [FK_{tableName}_Bags_BagID]
        FOREIGN KEY ([BagID]) REFERENCES [dbo].[Bags] ([BagID]) ON DELETE CASCADE;

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_{tableName}_Belts_BeltID' AND parent_object_id = OBJECT_ID(N'dbo.{tableName}'))
    ALTER TABLE [dbo].[{tableName}] WITH CHECK ADD CONSTRAINT [FK_{tableName}_Belts_BeltID]
        FOREIGN KEY ([BeltID]) REFERENCES [dbo].[Belts] ([BeltID]) ON DELETE CASCADE;

Skip_{tableName}:
";
}
