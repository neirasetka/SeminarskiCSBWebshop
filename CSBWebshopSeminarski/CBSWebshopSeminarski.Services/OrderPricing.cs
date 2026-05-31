using CSBWebshopSeminarski.Core.Entities;

namespace CBSWebshopSeminarski.Services
{
    /// <summary>
    /// Single source of truth for order line and order totals (cart persistence and Stripe amounts).
    /// </summary>
    public static class OrderPricing
    {
        /// <summary>Stripe minimum charge: 0.50 KM (50 minor units for BAM).</summary>
        public const long MinimumAmountInMinorUnits = 50;

        public static decimal GetUnitPrice(OrderItems item)
        {
            if (item.Price is > 0)
                return item.Price.Value;

            if (item.Bag != null)
                return item.Bag.Price;

            if (item.Belt != null)
                return item.Belt.Price;

            return 0m;
        }

        public static decimal ComputeLineTotal(OrderItems item)
        {
            var unitPrice = GetUnitPrice(item);
            var qty = item.Quantity ?? 1;
            var discount = item.Discount ?? 0m;
            return unitPrice * qty * (1 - discount / 100m);
        }

        public static decimal ComputeOrderTotal(IEnumerable<OrderItems> items, Func<OrderItems, bool>? includeItem = null)
        {
            decimal total = 0m;
            foreach (var item in items)
            {
                if (includeItem != null && !includeItem(item))
                    continue;

                total += ComputeLineTotal(item);
            }

            return total;
        }

        public static (long amountInCents, string? error) ToPaymentAmountInCents(decimal total)
        {
            if (total <= 0m)
                return (0, "Order total is too small for payment (minimum 0.50 KM).");

            var cents = (long)Math.Round(total * 100m, MidpointRounding.AwayFromZero);
            if (cents < MinimumAmountInMinorUnits)
                return (0, "Order total is too small for payment (minimum 0.50 KM).");

            return (cents, null);
        }
    }
}
