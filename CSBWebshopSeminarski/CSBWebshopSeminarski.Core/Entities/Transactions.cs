using System.ComponentModel.DataAnnotations;

namespace CSBWebshopSeminarski.Core.Entities
{
    public class Transactions
    {
        [Key]
        public int TransactionID { get; set; }
        public int UserID { get; set; }
        public Users User { get; set; } = null!;
        public DateTime TransactionDate { get; set; }
        public float Price { get; set; }
        public string OrderNumber { get; set; } = null!;
        public string Username { get; set; } = null!;
        public int OrderID { get; set; }
        public Orders Order { get; set; } = null!;
    }
}
