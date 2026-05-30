namespace CBSWebshopSeminarski.Services;

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

    public static void ValidateExactlyOne(int? bagId, int? beltId, string entityName = "Record")
    {
        var (bag, belt) = Normalize(bagId, beltId);

        if (!bag.HasValue && !belt.HasValue)
            throw new ValidationException($"{entityName} must have either BagID or BeltID.");

        if (bag.HasValue && belt.HasValue)
            throw new ValidationException($"{entityName} cannot specify both BagID and BeltID.");
    }
}
