using System.ComponentModel.DataAnnotations;

namespace CBSWebshopSeminarski.Model
{
    /// <summary>
    /// Zajednička cross-field validacija: tačno jedno od BagID ili BeltID mora biti postavljeno.
    /// </summary>
    public static class BagOrBeltReferenceValidation
    {
        public static IEnumerable<ValidationResult> ValidateExactlyOne(
            int? bagId,
            int? beltId,
            string entityName = "Zapis")
        {
            var normalizedBagId = bagId is > 0 ? bagId : null;
            var normalizedBeltId = beltId is > 0 ? beltId : null;

            if (!normalizedBagId.HasValue && !normalizedBeltId.HasValue)
            {
                yield return new ValidationResult(
                    $"{entityName} mora referencirati ili torbu ili kaiš.",
                    new[] { nameof(bagId), nameof(beltId) });
            }

            if (normalizedBagId.HasValue && normalizedBeltId.HasValue)
            {
                yield return new ValidationResult(
                    $"{entityName} ne smije referencirati i torbu i kaiš istovremeno.",
                    new[] { nameof(bagId), nameof(beltId) });
            }
        }
    }
}
