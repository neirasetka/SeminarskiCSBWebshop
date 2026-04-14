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
}
