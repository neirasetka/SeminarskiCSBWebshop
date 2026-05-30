using System.ComponentModel.DataAnnotations;

namespace CBSWebshopSeminarski.Model
{
    /// <summary>
    /// Shared cross-field validation: exactly one of BagID or BeltID must be set.
    /// </summary>
    public static class BagOrBeltReferenceValidation
    {
        public static IEnumerable<ValidationResult> ValidateExactlyOne(
            int? bagId,
            int? beltId,
            string entityName = "Record")
        {
            var normalizedBagId = bagId is > 0 ? bagId : null;
            var normalizedBeltId = beltId is > 0 ? beltId : null;

            if (!normalizedBagId.HasValue && !normalizedBeltId.HasValue)
            {
                yield return new ValidationResult(
                    $"{entityName} must have either BagID or BeltID.",
                    new[] { nameof(bagId), nameof(beltId) });
            }

            if (normalizedBagId.HasValue && normalizedBeltId.HasValue)
            {
                yield return new ValidationResult(
                    $"{entityName} cannot specify both BagID and BeltID.",
                    new[] { nameof(bagId), nameof(beltId) });
            }
        }
    }
}
