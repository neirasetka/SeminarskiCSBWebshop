namespace CSBWebshopSeminarski.Database;

/// <summary>
/// Idempotent SQL: creates <c>PasswordResetTokens</c> when migrations were not applied.
/// </summary>
public static class PasswordResetTokensSchemaCompatibility
{
    public const string EnsurePasswordResetTokensTableSql = @"
IF OBJECT_ID(N'dbo.Users', N'U') IS NULL
    RETURN;

IF OBJECT_ID(N'dbo.PasswordResetTokens', N'U') IS NULL
BEGIN
    CREATE TABLE [dbo].[PasswordResetTokens] (
        [Id] int NOT NULL IDENTITY,
        [UserID] int NOT NULL,
        [Token] nvarchar(128) NOT NULL,
        [ExpiresAt] datetime2 NOT NULL,
        [Used] bit NOT NULL,
        [CreatedAt] datetime2 NOT NULL CONSTRAINT [DF_PasswordResetTokens_CreatedAt] DEFAULT (GETUTCDATE()),
        CONSTRAINT [PK_PasswordResetTokens] PRIMARY KEY ([Id]),
        CONSTRAINT [FK_PasswordResetTokens_Users_UserID] FOREIGN KEY ([UserID]) REFERENCES [dbo].[Users] ([UserID]) ON DELETE CASCADE
    );

    CREATE UNIQUE INDEX [IX_PasswordResetTokens_Token] ON [dbo].[PasswordResetTokens] ([Token]);
    CREATE INDEX [IX_PasswordResetTokens_UserID] ON [dbo].[PasswordResetTokens] ([UserID]);
END
";
}
