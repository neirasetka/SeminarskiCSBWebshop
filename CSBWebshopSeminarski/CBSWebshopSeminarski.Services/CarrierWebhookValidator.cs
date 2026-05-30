using CBSWebshopSeminarski.Model.Requests;
using CBSWebshopSeminarski.Services.Exceptions;

namespace CBSWebshopSeminarski.Services;

/// <summary>
/// Validates carrier webhook simulation payloads (Development only endpoint).
/// </summary>
public static class CarrierWebhookValidator
{
    private const int MaxCarrierCodeLength = 50;
    private const int MaxTrackingNumberLength = 100;
    private const int MaxStatusLength = 64;
    private const int MaxMessageLength = 500;
    private const int MaxLocationLength = 200;
    private const int MaxRawJsonLength = 10_000;

    private static readonly HashSet<string> AllowedStatuses = new(StringComparer.OrdinalIgnoreCase)
    {
        "shipped",
        "in_transit",
        "in transit",
        "customs",
        "at_customs",
        "out_for_delivery",
        "out for delivery",
        "delivered",
        "returned",
        "cancelled"
    };

    public static void Validate(string? carrierCode, CarrierWebhookPayload? payload)
    {
        if (payload == null)
            throw new ValidationException("Request body is required.");

        if (string.IsNullOrWhiteSpace(carrierCode))
            throw new ValidationException("Carrier code is required.");

        if (carrierCode.Trim().Length > MaxCarrierCodeLength)
            throw new ValidationException($"Carrier code must not exceed {MaxCarrierCodeLength} characters.");

        var hasOrderId = payload.OrderID is > 0;
        var hasTrackingNumber = !string.IsNullOrWhiteSpace(payload.TrackingNumber);

        if (!hasOrderId && !hasTrackingNumber)
            throw new ValidationException("Either OrderID or TrackingNumber must be provided.");

        if (payload.OrderID.HasValue && payload.OrderID.Value <= 0)
            throw new ValidationException("OrderID must be a positive integer when provided.");

        if (payload.TrackingNumber != null && payload.TrackingNumber.Length > MaxTrackingNumberLength)
            throw new ValidationException($"TrackingNumber must not exceed {MaxTrackingNumberLength} characters.");

        if (string.IsNullOrWhiteSpace(payload.Status))
            throw new ValidationException("Status is required.");

        if (payload.Status.Trim().Length > MaxStatusLength)
            throw new ValidationException($"Status must not exceed {MaxStatusLength} characters.");

        if (!AllowedStatuses.Contains(payload.Status.Trim()))
        {
            throw new ValidationException(
                "Status is not supported. Allowed values: shipped, in_transit, at_customs, out_for_delivery, delivered, returned, cancelled.");
        }

        if (payload.Message != null && payload.Message.Length > MaxMessageLength)
            throw new ValidationException($"Message must not exceed {MaxMessageLength} characters.");

        if (payload.Location != null && payload.Location.Length > MaxLocationLength)
            throw new ValidationException($"Location must not exceed {MaxLocationLength} characters.");

        if (payload.RawJson != null && payload.RawJson.Length > MaxRawJsonLength)
            throw new ValidationException($"RawJson must not exceed {MaxRawJsonLength} characters.");
    }
}
