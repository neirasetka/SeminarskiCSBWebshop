namespace CSBWebshopSeminarski.Database;

/// <summary>
/// Idempotent SQL: enforces one purchase row per order for legacy DBs.
/// </summary>
public static class PurchasesSchemaCompatibility
{
    public const string EnsureUniquePurchaseOrderIdIndexSql = @"
IF OBJECT_ID(N'dbo.Purchases', N'U') IS NULL
    RETURN;

IF EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = N'IX_Purchases_OrderID'
      AND object_id = OBJECT_ID(N'dbo.Purchases')
      AND is_unique = 0)
BEGIN
    DROP INDEX [IX_Purchases_OrderID] ON [dbo].[Purchases];
END

IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = N'IX_Purchases_OrderID'
      AND object_id = OBJECT_ID(N'dbo.Purchases'))
BEGIN
    CREATE UNIQUE INDEX [IX_Purchases_OrderID] ON [dbo].[Purchases]([OrderID]);
END
";
}
