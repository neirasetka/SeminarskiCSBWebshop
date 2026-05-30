namespace CSBWebshopSeminarski.Database;

/// <summary>
/// Idempotent SQL: unique indexes on business identifiers (Users, Orders, Purchases).
/// Indexed string columns must be bounded (not nvarchar(max)) for SQL Server.
/// </summary>
public static class BusinessIdentifiersSchemaCompatibility
{
    public const string EnsureBusinessIdentifierUniqueIndexesSql = @"
IF OBJECT_ID(N'dbo.Users', N'U') IS NOT NULL
BEGIN
    IF COL_LENGTH(N'dbo.Users', N'UserName') IS NOT NULL
        ALTER TABLE [dbo].[Users] ALTER COLUMN [UserName] NVARCHAR(256) NOT NULL;

    IF COL_LENGTH(N'dbo.Users', N'Email') IS NOT NULL
        ALTER TABLE [dbo].[Users] ALTER COLUMN [Email] NVARCHAR(256) NOT NULL;

    IF EXISTS (
        SELECT 1 FROM sys.indexes
        WHERE name = N'IX_Users_UserName' AND object_id = OBJECT_ID(N'dbo.Users') AND is_unique = 0)
        DROP INDEX [IX_Users_UserName] ON [dbo].[Users];

    IF NOT EXISTS (
        SELECT 1 FROM sys.indexes
        WHERE name = N'IX_Users_UserName' AND object_id = OBJECT_ID(N'dbo.Users'))
        CREATE UNIQUE INDEX [IX_Users_UserName] ON [dbo].[Users]([UserName]);

    IF EXISTS (
        SELECT 1 FROM sys.indexes
        WHERE name = N'IX_Users_Email' AND object_id = OBJECT_ID(N'dbo.Users') AND is_unique = 0)
        DROP INDEX [IX_Users_Email] ON [dbo].[Users];

    IF NOT EXISTS (
        SELECT 1 FROM sys.indexes
        WHERE name = N'IX_Users_Email' AND object_id = OBJECT_ID(N'dbo.Users'))
        CREATE UNIQUE INDEX [IX_Users_Email] ON [dbo].[Users]([Email]);
END

IF OBJECT_ID(N'dbo.Orders', N'U') IS NOT NULL
BEGIN
    IF COL_LENGTH(N'dbo.Orders', N'OrderNumber') IS NOT NULL
        ALTER TABLE [dbo].[Orders] ALTER COLUMN [OrderNumber] NVARCHAR(64) NOT NULL;

    IF EXISTS (
        SELECT 1 FROM sys.indexes
        WHERE name = N'IX_Orders_OrderNumber' AND object_id = OBJECT_ID(N'dbo.Orders') AND is_unique = 0)
        DROP INDEX [IX_Orders_OrderNumber] ON [dbo].[Orders];

    IF NOT EXISTS (
        SELECT 1 FROM sys.indexes
        WHERE name = N'IX_Orders_OrderNumber' AND object_id = OBJECT_ID(N'dbo.Orders'))
        CREATE UNIQUE INDEX [IX_Orders_OrderNumber] ON [dbo].[Orders]([OrderNumber]);
END

IF OBJECT_ID(N'dbo.Purchases', N'U') IS NOT NULL
BEGIN
    IF COL_LENGTH(N'dbo.Purchases', N'StripeId') IS NOT NULL
        ALTER TABLE [dbo].[Purchases] ALTER COLUMN [StripeId] NVARCHAR(255) NOT NULL;

    IF EXISTS (
        SELECT 1 FROM sys.indexes
        WHERE name = N'IX_Purchases_StripeId' AND object_id = OBJECT_ID(N'dbo.Purchases') AND is_unique = 0)
        DROP INDEX [IX_Purchases_StripeId] ON [dbo].[Purchases];

    IF NOT EXISTS (
        SELECT 1 FROM sys.indexes
        WHERE name = N'IX_Purchases_StripeId' AND object_id = OBJECT_ID(N'dbo.Purchases'))
        CREATE UNIQUE INDEX [IX_Purchases_StripeId] ON [dbo].[Purchases]([StripeId]);
END
";

}
