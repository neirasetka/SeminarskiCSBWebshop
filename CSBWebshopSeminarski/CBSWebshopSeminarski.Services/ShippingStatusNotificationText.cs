using CSBWebshopSeminarski.Core.Entities;

namespace CBSWebshopSeminarski.Services;

internal static class ShippingStatusNotificationText
{
    internal static (string Title, string Message)? ForStatus(ShippingStatus status, string orderNumber)
    {
        return status switch
        {
            ShippingStatus.Processing => (
                "Narudžba u obradi",
                $"Narudžba #{orderNumber} se obrađuje."),
            ShippingStatus.Shipped => (
                "Narudžba poslana",
                $"Narudžba #{orderNumber} je predana kuriru."),
            ShippingStatus.InTransit => (
                "Narudžba u transportu",
                $"Narudžba #{orderNumber} je u transportu."),
            ShippingStatus.AtCustoms => (
                "Narudžba na carini",
                $"Narudžba #{orderNumber} je na carinskoj kontroli."),
            ShippingStatus.OutForDelivery => (
                "Narudžba u dostavi",
                $"Narudžba #{orderNumber} je u dostavi."),
            ShippingStatus.Delivered => (
                "Narudžba isporučena",
                $"Narudžba #{orderNumber} je isporučena."),
            ShippingStatus.Cancelled => (
                "Narudžba otkazana",
                $"Narudžba #{orderNumber} je otkazana."),
            ShippingStatus.Returned => (
                "Narudžba vraćena",
                $"Narudžba #{orderNumber} je vraćena pošiljatelju."),
            _ => null
        };
    }
}
