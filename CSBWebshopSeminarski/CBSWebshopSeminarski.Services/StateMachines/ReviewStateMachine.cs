using CBSWebshopSeminarski.Services.Exceptions;
using CSBWebshopSeminarski.Core.Entities;

namespace CBSWebshopSeminarski.Services.StateMachines
{
    public static class ReviewStateMachine
    {
        private static readonly Dictionary<ReviewStatus, HashSet<ReviewStatus>> Transitions = new()
        {
            { ReviewStatus.Pending, new HashSet<ReviewStatus> { ReviewStatus.Approved, ReviewStatus.Rejected } },
            { ReviewStatus.Approved, new HashSet<ReviewStatus> { ReviewStatus.Pending, ReviewStatus.Rejected } },
            { ReviewStatus.Rejected, new HashSet<ReviewStatus> { ReviewStatus.Pending, ReviewStatus.Approved } }
        };

        public static bool CanTransition(ReviewStatus from, ReviewStatus to)
        {
            if (from == to)
                return true;

            return Transitions.TryGetValue(from, out var allowed) && allowed.Contains(to);
        }

        public static void ValidateTransition(ReviewStatus from, ReviewStatus to)
        {
            if (!CanTransition(from, to))
                throw new BusinessException($"Cannot transition review status from {from} to {to}.");
        }
    }
}
