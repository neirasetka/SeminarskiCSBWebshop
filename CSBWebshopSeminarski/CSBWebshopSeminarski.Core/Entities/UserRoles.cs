namespace CSBWebshopSeminarski.Core.Entities
{
    public class UserRoles
    {
        public int UserRolesID { get; set; }
        public int UserID { get; set; }
        public virtual Users User { get; set; } = null!;
        public int RolesID { get; set; }
        public virtual Roles Roles { get; set; } = null!;
    }
}
