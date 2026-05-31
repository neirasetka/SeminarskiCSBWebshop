namespace CSBWebshopSeminarski.Database;

/// <summary>
/// Idempotent SQL: creates <c>Notifications</c> when migrations were not applied.
/// </summary>
public static class NotificationsSchemaCompatibility
{
    public const string EnsureNotificationsTableSql = @"
IF OBJECT_ID(N'dbo.Users', N'U') IS NULL
    RETURN;

IF OBJECT_ID(N'dbo.Notifications', N'U') IS NULL
BEGIN
    CREATE TABLE [dbo].[Notifications] (
        [NotificationID] int NOT NULL IDENTITY,
        [UserID] int NOT NULL,
        [Type] nvarchar(64) NOT NULL,
        [Title] nvarchar(200) NOT NULL,
        [Message] nvarchar(1000) NOT NULL,
        [RelatedEntityID] int NULL,
        [IsRead] bit NOT NULL,
        [CreatedAt] datetime2 NOT NULL,
        CONSTRAINT [PK_Notifications] PRIMARY KEY ([NotificationID]),
        CONSTRAINT [FK_Notifications_Users_UserID] FOREIGN KEY ([UserID]) REFERENCES [dbo].[Users] ([UserID]) ON DELETE CASCADE
    );

    CREATE INDEX [IX_Notifications_UserID_IsRead] ON [dbo].[Notifications] ([UserID], [IsRead]);
END
";
}
