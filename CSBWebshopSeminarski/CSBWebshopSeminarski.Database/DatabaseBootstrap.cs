using Microsoft.Data.SqlClient;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;

namespace CSBWebshopSeminarski.Database;

/// <summary>
/// Applies EF migrations (creates the database when missing) and legacy schema patches on startup.
/// Retries while SQL Server is still starting (common in Docker).
/// </summary>
public static class DatabaseBootstrap
{
    private const int MaxAttempts = 30;
    private static readonly TimeSpan RetryDelay = TimeSpan.FromSeconds(2);

    public static async Task ApplyMigrationsAndSchemaPatchesAsync(
        CocoSunBagsWebshopDbContext context,
        ILogger logger,
        CancellationToken cancellationToken = default)
    {
        await WaitAndMigrateAsync(context, logger, cancellationToken);
        await ApplySchemaPatchesAsync(context, logger, cancellationToken);
    }

    private static async Task WaitAndMigrateAsync(
        CocoSunBagsWebshopDbContext context,
        ILogger logger,
        CancellationToken cancellationToken)
    {
        Exception? lastNonTransient = null;

        for (var attempt = 1; attempt <= MaxAttempts; attempt++)
        {
            try
            {
                await context.Database.MigrateAsync(cancellationToken);
                logger.LogInformation("Database migrations applied successfully.");
                return;
            }
            catch (Exception ex) when (attempt < MaxAttempts && IsTransientSqlError(ex))
            {
                logger.LogWarning(
                    "SQL Server is not ready yet (attempt {Attempt}/{MaxAttempts}). Retrying in {DelaySeconds}s...",
                    attempt,
                    MaxAttempts,
                    RetryDelay.TotalSeconds);
                await Task.Delay(RetryDelay, cancellationToken);
            }
            catch (Exception ex)
            {
                lastNonTransient = ex;
                break;
            }
        }

        if (lastNonTransient != null)
        {
            logger.LogWarning(
                lastNonTransient,
                "EF migrations could not be fully applied (pending model changes or migration conflict). " +
                "Idempotent schema patches will still be attempted.");
        }
    }

    private static async Task ApplySchemaPatchesAsync(
        CocoSunBagsWebshopDbContext context,
        ILogger logger,
        CancellationToken cancellationToken)
    {
        // Patches are idempotent and no-op when tables/columns are already correct.
        // They run after MigrateAsync so a fresh Docker volume gets schema from migrations first.
        var patches = new (string Name, string Sql)[]
        {
            ("OrderItems bag/belt nullable", OrderItemsSchemaCompatibility.EnsureOrderItemsBagOrBeltColumnsNullableSql),
            ("Orders payment confirmation flag", OrdersSchemaCompatibility.EnsurePaymentConfirmationEmailSentColumnSql),
            ("Orders Stripe refs", OrdersSchemaCompatibility.EnsureStripePaymentRefColumnsSql),
            ("Orders cancellation fields", OrdersSchemaCompatibility.EnsureOrderCancellationColumnsSql),
            ("Purchases unique order index", PurchasesSchemaCompatibility.EnsureUniquePurchaseOrderIdIndexSql),
            ("Reviews/rates/favorites XOR", ProductBagBeltSchemaCompatibility.EnsureReviewsRatesFavoritesBagOrBeltXorSql),
            ("Business identifier indexes", BusinessIdentifiersSchemaCompatibility.EnsureBusinessIdentifierUniqueIndexesSql),
            ("Password reset tokens", PasswordResetTokensSchemaCompatibility.EnsurePasswordResetTokensTableSql),
            ("In-app notifications", NotificationsSchemaCompatibility.EnsureNotificationsTableSql),
            ("User soft delete", UsersSchemaCompatibility.EnsureUserSoftDeleteColumnsSql),
        };

        foreach (var (name, sql) in patches)
        {
            try
            {
                await context.Database.ExecuteSqlRawAsync(sql, cancellationToken);
            }
            catch (Exception ex)
            {
                logger.LogWarning(ex, "Schema patch '{PatchName}' could not be applied.", name);
            }
        }
    }

    private static bool IsTransientSqlError(Exception ex)
    {
        for (var current = ex; current != null; current = current.InnerException)
        {
            if (current is TimeoutException)
            {
                return true;
            }

            if (current is SqlException sqlEx)
            {
                if (sqlEx.Number is -2 or 2 or 64 or 233 or 10053 or 10054 or 10060
                    or 40197 or 40501 or 40613)
                {
                    return true;
                }
            }
        }

        var message = ex.Message;
        return message.Contains("network-related", StringComparison.OrdinalIgnoreCase)
               || message.Contains("server was not found", StringComparison.OrdinalIgnoreCase)
               || message.Contains("establishing a connection", StringComparison.OrdinalIgnoreCase)
               || message.Contains("not ready", StringComparison.OrdinalIgnoreCase);
    }
}
