namespace CBSWebshopSeminarski.Services;

using CBSWebshopSeminarski.Model;
using CBSWebshopSeminarski.Services.Exceptions;

/// <summary>
/// Validates that a row refers to exactly one product: either a bag or a belt.
/// </summary>
public static class BagOrBeltReferenceValidator
{
    public static (int? BagID, int? BeltID) Normalize(int? bagId, int? beltId)
    {
        bagId = bagId is > 0 ? bagId : null;
        beltId = beltId is > 0 ? beltId : null;
        return (bagId, beltId);
    }

    public static void ValidateExactlyOne(int? bagId, int? beltId, string entityName = "Zapis")
    {
        var (bag, belt) = Normalize(bagId, beltId);

        if (!bag.HasValue && !belt.HasValue)
            throw new ValidationException($"{entityName} mora referencirati ili torbu ili kaiš.");

        if (bag.HasValue && belt.HasValue)
            throw new ValidationException($"{entityName} ne smije referencirati i torbu i kaiš istovremeno.");
    }
}
