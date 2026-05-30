using CSBWebshopSeminarski.Database;
using Microsoft.EntityFrameworkCore.Storage;

namespace CBSWebshopSeminarski.Services
{
    public static class DatabaseTransactionExtensions
    {
        public static async Task ExecuteInTransactionAsync(
            this CocoSunBagsWebshopDbContext context,
            Func<Task> action)
        {
            await using IDbContextTransaction transaction = await context.Database.BeginTransactionAsync();
            try
            {
                await action();
                await transaction.CommitAsync();
            }
            catch
            {
                await transaction.RollbackAsync();
                throw;
            }
        }

        public static async Task<T> ExecuteInTransactionAsync<T>(
            this CocoSunBagsWebshopDbContext context,
            Func<Task<T>> action)
        {
            await using IDbContextTransaction transaction = await context.Database.BeginTransactionAsync();
            try
            {
                var result = await action();
                await transaction.CommitAsync();
                return result;
            }
            catch
            {
                await transaction.RollbackAsync();
                throw;
            }
        }
    }
}
