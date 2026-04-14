namespace CSBWebshopSeminarski.Database;

/// <summary>
/// Idempotent SQL so <c>OrderItems</c> can store either a bag line or a belt line (one FK null).
/// Older schemas (and the baseline <c>newDatabase</c> migration) marked both columns NOT NULL,
/// which breaks <c>AddToCart</c> when only <c>BeltID</c> or only <c>BagID</c> is set.
/// </summary>
public static class OrderItemsSchemaCompatibility
{
    /// <summary>
    /// Drops FKs and default constraints that block <c>ALTER COLUMN ... NULL</c>, then makes
    /// <c>BagID</c>/<c>BeltID</c> nullable and re-adds the standard foreign keys.
    /// </summary>
    public const string EnsureOrderItemsBagOrBeltColumnsNullableSql = @"
IF OBJECT_ID(N'dbo.OrderItems', N'U') IS NULL
    RETURN;

-- Nothing to do if both columns are absent, or every present column is already nullable
IF NOT EXISTS (
    SELECT 1
    FROM sys.columns c
    INNER JOIN sys.tables t ON c.object_id = t.object_id
    INNER JOIN sys.schemas s ON t.schema_id = s.schema_id
    WHERE s.name = N'dbo' AND t.name = N'OrderItems' AND c.name IN (N'BagID', N'BeltID')
      AND c.is_nullable = 0)
    RETURN;

DECLARE @constraintName sysname;
DECLARE @dropSql nvarchar(max);

-- Drop all foreign keys on OrderItems that use BagID or BeltID (names may differ on legacy DBs)
WHILE 1 = 1
BEGIN
    SELECT TOP (1) @constraintName = fk.name
    FROM sys.foreign_keys AS fk
    INNER JOIN sys.foreign_key_columns AS fkc ON fk.object_id = fkc.constraint_object_id
    INNER JOIN sys.columns AS col ON fkc.parent_object_id = col.object_id AND fkc.parent_column_id = col.column_id
    WHERE fk.parent_object_id = OBJECT_ID(N'dbo.OrderItems')
      AND col.name IN (N'BagID', N'BeltID');
    IF @constraintName IS NULL BREAK;
    SET @dropSql = N'ALTER TABLE [dbo].[OrderItems] DROP CONSTRAINT ' + N'[' + REPLACE(@constraintName, N']', N']]') + N'];';
    EXEC sys.sp_executesql @dropSql;
    SET @constraintName = NULL;
END;

-- Drop default constraints on those columns (otherwise ALTER can fail on some databases)
WHILE 1 = 1
BEGIN
    SELECT TOP (1) @constraintName = dc.name
    FROM sys.default_constraints AS dc
    INNER JOIN sys.columns AS c ON dc.parent_object_id = c.object_id AND dc.parent_column_id = c.column_id
    WHERE dc.parent_object_id = OBJECT_ID(N'dbo.OrderItems')
      AND c.name IN (N'BagID', N'BeltID');
    IF @constraintName IS NULL BREAK;
    SET @dropSql = N'ALTER TABLE [dbo].[OrderItems] DROP CONSTRAINT ' + N'[' + REPLACE(@constraintName, N']', N']]') + N'];';
    EXEC sys.sp_executesql @dropSql;
    SET @constraintName = NULL;
END;

IF COL_LENGTH(N'dbo.OrderItems', N'BagID') IS NOT NULL
    ALTER TABLE [dbo].[OrderItems] ALTER COLUMN [BagID] INT NULL;

IF COL_LENGTH(N'dbo.OrderItems', N'BeltID') IS NOT NULL
    ALTER TABLE [dbo].[OrderItems] ALTER COLUMN [BeltID] INT NULL;

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_OrderItems_Bags_BagID' AND parent_object_id = OBJECT_ID(N'dbo.OrderItems'))
    ALTER TABLE [dbo].[OrderItems] WITH CHECK ADD CONSTRAINT [FK_OrderItems_Bags_BagID]
        FOREIGN KEY ([BagID]) REFERENCES [dbo].[Bags] ([BagID]) ON DELETE CASCADE;

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_OrderItems_Belts_BeltID' AND parent_object_id = OBJECT_ID(N'dbo.OrderItems'))
    ALTER TABLE [dbo].[OrderItems] WITH CHECK ADD CONSTRAINT [FK_OrderItems_Belts_BeltID]
        FOREIGN KEY ([BeltID]) REFERENCES [dbo].[Belts] ([BeltID]) ON DELETE CASCADE;
";
}
