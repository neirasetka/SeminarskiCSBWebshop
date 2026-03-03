using System.ComponentModel.DataAnnotations;

namespace CSBWebshopSeminarski.Core.Entities
{
    public class Users
    {
        [Key]
        public int UserID { get; set; }
        public string Name { get; set; } = null!;
        public string Surname { get; set; } = null!;
        public string Email { get; set; } = null!;
        public string Phone { get; set; } = null!;
        public string UserName { get; set; } = null!;
        public string PasswordHash { get; set; } = null!;
        public string PasswordSalt { get; set; } = null!;
        public byte[] Image { get; set; } = null!;
        public virtual ICollection<UserRoles> UserRoles { get; set; } = null!;
        public virtual ICollection<Reviews> Reviews { get; set; } = null!;
        public virtual ICollection<Rates> Rates { get; set; } = null!;
    }
}
