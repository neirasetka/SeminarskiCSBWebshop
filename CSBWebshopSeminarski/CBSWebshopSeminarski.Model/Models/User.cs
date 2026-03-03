namespace CBSWebshopSeminarski.Model.Models
{
    public class User
    {
        public int UserID { get; set; }
        public string Name { get; set; } = null!;
        public string Surname { get; set; } = null!;
        public string Email { get; set; } = null!;
        public string Phone { get; set; } = null!;
        public string UserName { get; set; } = null!;
        public byte[] Image { get; set; } = null!;
        public ICollection<UserRole> UserRole { get; set; } = null!;
    }
}
