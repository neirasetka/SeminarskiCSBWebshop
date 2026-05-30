using CBSWebshopSeminarski.Services.Exceptions;
using CSBWebshopSeminarski.Core.Entities;

namespace CBSWebshopSeminarski.Services.StateMachines
{
    public static class OrderStateMachine
    {
        private static readonly Dictionary<PaymentStatus, HashSet<PaymentStatus>> PaymentTransitions = new()
        {
            { PaymentStatus.Pending, new HashSet<PaymentStatus> { PaymentStatus.Paid, PaymentStatus.Failed } },
            { PaymentStatus.Failed, new HashSet<PaymentStatus> { PaymentStatus.Pending } },
            { PaymentStatus.Paid, new HashSet<PaymentStatus> { PaymentStatus.Refunded } },
            { PaymentStatus.Refunded, new HashSet<PaymentStatus>() }
        };

        public static bool CanTransitionPayment(PaymentStatus from, PaymentStatus to)
        {
            if (from == to)
                return true;

            return PaymentTransitions.TryGetValue(from, out var allowed) && allowed.Contains(to);
        }

        public static void ValidatePaymentTransition(PaymentStatus from, PaymentStatus to)
        {
            if (!CanTransitionPayment(from, to))
                throw new BusinessException($"Cannot transition payment status from {from} to {to}.");
        }
    }
}
