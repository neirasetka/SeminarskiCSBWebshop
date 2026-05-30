namespace CSBWebshopSeminarski.Database;

/// <summary>
/// Idempotent SQL: adds <c>Orders.PaymentConfirmationEmailSent</c> for legacy DBs or when migrations were not applied.
/// </summary>
public static class OrdersSchemaCompatibility
{
    public const string EnsurePaymentConfirmationEmailSentColumnSql = @"
IF OBJECT_ID(N'dbo.Orders', N'U') IS NULL
    RETURN;

IF COL_LENGTH(N'dbo.Orders', N'PaymentConfirmationEmailSent') IS NULL
BEGIN
    ALTER TABLE [dbo].[Orders] ADD [PaymentConfirmationEmailSent] BIT NOT NULL
        CONSTRAINT [DF_Orders_PaymentConfirmationEmailSent] DEFAULT (0);
END
";

    public const string EnsureStripePaymentRefColumnsSql = @"
IF OBJECT_ID(N'dbo.Orders', N'U') IS NULL
    RETURN;

IF COL_LENGTH(N'dbo.Orders', N'StripePaymentIntentId') IS NULL
    ALTER TABLE [dbo].[Orders] ADD [StripePaymentIntentId] NVARCHAR(255) NULL;

IF COL_LENGTH(N'dbo.Orders', N'StripeCheckoutSessionId') IS NULL
    ALTER TABLE [dbo].[Orders] ADD [StripeCheckoutSessionId] NVARCHAR(255) NULL;
";

    public const string EnsureOrderCancellationColumnsSql = @"
IF OBJECT_ID(N'dbo.Orders', N'U') IS NULL
    RETURN;

IF COL_LENGTH(N'dbo.Orders', N'CancelledAt') IS NULL
    ALTER TABLE [dbo].[Orders] ADD [CancelledAt] DATETIME2 NULL;

IF COL_LENGTH(N'dbo.Orders', N'CancelledByUserId') IS NULL
    ALTER TABLE [dbo].[Orders] ADD [CancelledByUserId] INT NULL;

IF COL_LENGTH(N'dbo.Orders', N'CancellationReason') IS NULL
    ALTER TABLE [dbo].[Orders] ADD [CancellationReason] NVARCHAR(500) NULL;

IF NOT EXISTS (
    SELECT 1 FROM sys.foreign_keys
    WHERE name = N'FK_Orders_Users_CancelledByUserId'
      AND parent_object_id = OBJECT_ID(N'dbo.Orders'))
    ALTER TABLE [dbo].[Orders] WITH CHECK ADD CONSTRAINT [FK_Orders_Users_CancelledByUserId]
        FOREIGN KEY ([CancelledByUserId]) REFERENCES [dbo].[Users] ([UserID]) ON DELETE NO ACTION;
";
}
