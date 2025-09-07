namespace CBSWebshopSeminarski.Model.Models
{
    public class UserRole
    {
        public int UserRolesID { get; set; }
        public int UserID { get; set; }
        public int RolesID { get; set; }
        public Role Role { get; set; }
    }
}
