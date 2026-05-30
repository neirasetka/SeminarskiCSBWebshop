using System.ComponentModel.DataAnnotations;

namespace CSBWebshopSeminarski.Core.Entities
{
    public class PasswordResetTokens
    {
        [Key]
        public int Id { get; set; }
        public int UserID { get; set; }
        public string Token { get; set; } = null!;
        public DateTime ExpiresAt { get; set; }
        public bool Used { get; set; }
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
        public virtual Users User { get; set; } = null!;
    }
}
