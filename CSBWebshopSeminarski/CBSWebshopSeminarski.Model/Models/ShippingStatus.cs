using System;

namespace CBSWebshopSeminarski.Model.Models
{
    public enum ShippingStatus
    {
        Pending = 0,
        Shipped = 1,
        InTransit = 2,
        AtCustoms = 3,
        OutForDelivery = 4,
        Delivered = 5,
        Returned = 6,
        Cancelled = 7
    }
}