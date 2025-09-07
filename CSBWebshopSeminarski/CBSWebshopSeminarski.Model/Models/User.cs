namespace CBSWebshopSeminarski.Model.Models
{
    public class User
    {
        public int UserID { get; set; }
        public string Name { get; set; }
        public string Surname { get; set; }
        public string Email { get; set; }
        public string Phone { get; set; }
        public string UserName { get; set; }
        public byte[] Image { get; set; }
        public ICollection<UserRole> UserRole { get; set; }
    }
}
