using CBSWebshopSeminarski.Services.Exceptions;
using CSBWebshopSeminarski.Core.Entities;

namespace CBSWebshopSeminarski.Services.StateMachines
{
    public static class ShippingStateMachine
    {
        private static readonly Dictionary<ShippingStatus, HashSet<ShippingStatus>> Transitions = new()
        {
            {
                ShippingStatus.Pending,
                new HashSet<ShippingStatus>
                {
                    ShippingStatus.Processing,
                    ShippingStatus.Shipped,
                    ShippingStatus.Cancelled
                }
            },
            {
                ShippingStatus.Processing,
                new HashSet<ShippingStatus> { ShippingStatus.Shipped, ShippingStatus.Cancelled }
            },
            {
                ShippingStatus.Shipped,
                new HashSet<ShippingStatus>
                {
                    ShippingStatus.InTransit,
                    ShippingStatus.AtCustoms,
                    ShippingStatus.OutForDelivery,
                    ShippingStatus.Delivered,
                    ShippingStatus.Returned,
                    ShippingStatus.Cancelled
                }
            },
            {
                ShippingStatus.InTransit,
                new HashSet<ShippingStatus>
                {
                    ShippingStatus.AtCustoms,
                    ShippingStatus.OutForDelivery,
                    ShippingStatus.Delivered,
                    ShippingStatus.Returned,
                    ShippingStatus.Cancelled
                }
            },
            {
                ShippingStatus.AtCustoms,
                new HashSet<ShippingStatus>
                {
                    ShippingStatus.InTransit,
                    ShippingStatus.OutForDelivery,
                    ShippingStatus.Delivered,
                    ShippingStatus.Returned,
                    ShippingStatus.Cancelled
                }
            },
            {
                ShippingStatus.OutForDelivery,
                new HashSet<ShippingStatus>
                {
                    ShippingStatus.Delivered,
                    ShippingStatus.Returned,
                    ShippingStatus.Cancelled
                }
            },
            {
                ShippingStatus.Delivered,
                new HashSet<ShippingStatus> { ShippingStatus.Returned }
            },
            { ShippingStatus.Returned, new HashSet<ShippingStatus>() },
            { ShippingStatus.Cancelled, new HashSet<ShippingStatus>() }
        };

        public static bool CanTransition(ShippingStatus from, ShippingStatus to)
        {
            if (from == to)
                return true;

            return Transitions.TryGetValue(from, out var allowed) && allowed.Contains(to);
        }

        public static void ValidateTransition(ShippingStatus from, ShippingStatus to)
        {
            if (!CanTransition(from, to))
                throw new BusinessException($"Cannot transition shipping status from {from} to {to}.");
        }
    }
}
