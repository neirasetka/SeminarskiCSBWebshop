using System.Diagnostics.CodeAnalysis;
using CBSWebshopSeminarski.Services.Exceptions;
using Microsoft.EntityFrameworkCore;

namespace CBSWebshopSeminarski.Services
{
    internal static class DbUpdateExceptionMapper
    {
        [DoesNotReturn]
        public static void ThrowDeleteConflictOrRethrow(Exception ex, string? conflictMessage = null)
        {
            if (ex is DbUpdateConcurrencyException)
            {
                throw new ConflictException(
                    conflictMessage ?? "Stavka je u međuvremenu izmijenjena ili obrisana. Osvježite stranicu i pokušajte ponovno.");
            }

            if (ex is DbUpdateException dbEx && IsReferenceConstraintViolation(dbEx))
            {
                throw new ConflictException(
                    conflictMessage ?? "Nije moguće obrisati jer se stavka još koristi (npr. u narudžbi, favoritima ili recenzijama).");
            }

            throw ex;
        }

        [DoesNotReturn]
        public static void ThrowCartInsertOrRethrow(DbUpdateException ex)
        {
            var inner = GetInnermostMessage(ex);
            if (ContainsForeignKeyViolation(inner))
            {
                throw new NotFoundException(
                    "Greška pri dodavanju u korpu: narudžba, torba ili kaiš nije pronađen. Osvježite stranicu i pokušajte ponovno.");
            }

            if (inner.Contains("Cannot insert the value NULL into column", StringComparison.OrdinalIgnoreCase)
                && (inner.Contains("BagID", StringComparison.OrdinalIgnoreCase)
                    || inner.Contains("BeltID", StringComparison.OrdinalIgnoreCase)))
            {
                throw new ValidationException(
                    "Struktura baze ne dopušta stavku samo s torbom ili samo s kaišem. Ponovno pokrenite web API (pri pokretanju se ispravljaju stupci OrderItems.BagID/BeltID). Ako problem ostane, ručno postavite te stupce na NULL u SQL Serveru.");
            }

            throw new BusinessException("Greška pri dodavanju u korpu. Osvježite stranicu i pokušajte ponovno.");
        }

        [DoesNotReturn]
        public static void ThrowOutfitIdeaInsertOrRethrow(DbUpdateException ex)
        {
            var inner = GetInnermostMessage(ex);
            if (ContainsForeignKeyViolation(inner))
            {
                throw new NotFoundException(
                    "Greška pri kreiranju outfit ideje: referencirani kaiš, torba ili korisnik ne postoji u bazi.");
            }

            if (inner.Contains("duplicate", StringComparison.OrdinalIgnoreCase)
                || inner.Contains("unique", StringComparison.OrdinalIgnoreCase))
            {
                throw new ConflictException(
                    "Greška pri kreiranju outfit ideje: outfit ideja za ovaj proizvod i korisnika već postoji.");
            }

            throw new BusinessException(
                "Greška pri kreiranju outfit ideje. Provjerite podatke i pokušajte ponovno.");
        }

        private static bool IsReferenceConstraintViolation(DbUpdateException ex) =>
            ContainsForeignKeyViolation(GetInnermostMessage(ex));

        private static bool ContainsForeignKeyViolation(string message) =>
            message.Contains("REFERENCE constraint", StringComparison.OrdinalIgnoreCase)
            || message.Contains("FOREIGN KEY", StringComparison.OrdinalIgnoreCase)
            || message.Contains("FK_", StringComparison.OrdinalIgnoreCase)
            || message.Contains("foreign key constraint", StringComparison.OrdinalIgnoreCase)
            || message.Contains("The DELETE statement conflicted", StringComparison.OrdinalIgnoreCase);

        private static string GetInnermostMessage(Exception ex)
        {
            var message = ex.Message;
            for (var inner = ex.InnerException; inner != null; inner = inner.InnerException)
            {
                message = inner.Message;
            }

            return message;
        }
    }
}
