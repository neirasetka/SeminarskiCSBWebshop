using CSBWebshopSeminarski.Core.Entities;

namespace CBSWebshopSeminarski.Services.StateMachines
{
    public static class OrderStateMachine
    {
        private static readonly Dictionary<PaymentStatus, HashSet<PaymentStatus>> PaymentTransitions = new()
        {
            { PaymentStatus.Pending, new HashSet<PaymentStatus> { PaymentStatus.Paid, PaymentStatus.Failed } },
            { PaymentStatus.Failed, new HashSet<PaymentStatus> { PaymentStatus.Pending } },
            { PaymentStatus.Paid, new HashSet<PaymentStatus>() }
        };

        private static readonly Dictionary<ShippingStatus, HashSet<ShippingStatus>> ShippingTransitions = new()
        {
            { ShippingStatus.Pending, new HashSet<ShippingStatus> { ShippingStatus.Processing, ShippingStatus.Cancelled } },
            { ShippingStatus.Processing, new HashSet<ShippingStatus> { ShippingStatus.InTransit, ShippingStatus.Cancelled } },
            { ShippingStatus.InTransit, new HashSet<ShippingStatus> { ShippingStatus.Delivered, ShippingStatus.Cancelled } },
            { ShippingStatus.Delivered, new HashSet<ShippingStatus>() },
            { ShippingStatus.Cancelled, new HashSet<ShippingStatus>() }
        };

        public static bool CanTransitionPayment(PaymentStatus from, PaymentStatus to)
        {
            return PaymentTransitions.TryGetValue(from, out var allowed) && allowed.Contains(to);
        }

        public static bool CanTransitionShipping(ShippingStatus from, ShippingStatus to)
        {
            return ShippingTransitions.TryGetValue(from, out var allowed) && allowed.Contains(to);
        }

        public static void ValidatePaymentTransition(PaymentStatus from, PaymentStatus to)
        {
            if (!CanTransitionPayment(from, to))
                throw new InvalidOperationException($"Cannot transition payment status from {from} to {to}.");
        }

        public static void ValidateShippingTransition(ShippingStatus from, ShippingStatus to)
        {
            if (!CanTransitionShipping(from, to))
                throw new InvalidOperationException($"Cannot transition shipping status from {from} to {to}.");
        }
    }
}
