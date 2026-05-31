namespace CSBWebshopSeminarski.Database;

/// <summary>
/// Idempotent SQL: adds user soft-delete columns for legacy DBs when migrations were not applied.
/// </summary>
public static class UsersSchemaCompatibility
{
    public const string EnsureUserSoftDeleteColumnsSql = @"
IF OBJECT_ID(N'dbo.Users', N'U') IS NULL
    RETURN;

IF COL_LENGTH(N'dbo.Users', N'IsDeleted') IS NULL
BEGIN
    ALTER TABLE [dbo].[Users] ADD [IsDeleted] BIT NOT NULL
        CONSTRAINT [DF_Users_IsDeleted] DEFAULT (0);
END

IF COL_LENGTH(N'dbo.Users', N'DeletedAt') IS NULL
    ALTER TABLE [dbo].[Users] ADD [DeletedAt] DATETIME2 NULL;
";
}
