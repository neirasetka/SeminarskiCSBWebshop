using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace CBSWebshopSeminarski.Model.Models
{
    public class Order
    {
        public int OrderID { get; set; }
        public string OrderNumber { get; set; }
        public DateTime Date { get; set; }
        public int UserID { get; set; }
        public decimal Amount { get; set; }
        public string UserUserName { get; set; }
        public ICollection<OrderItem> OrderItems { get; set; }

        // Shipping projection fields
        public string? TrackingNumber { get; set; }
        public string? CarrierCode { get; set; }
        public ShippingStatus ShippingStatus { get; set; }
        public DateTime? LastStatusUpdate { get; set; }
        public DateTime? EstimatedDeliveryDate { get; set; }

        // Payment projection
        public string? PaymentStatus { get; set; }
    }
}
