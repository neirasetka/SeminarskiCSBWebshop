namespace CBSWebshopSeminarski.Model.ViewModels
{
    public class UserListVM
    {
        public int UserID { get; set; }
        public string Name { get; set; } = null!;
        public string Surname { get; set; } = null!;
        public string Email { get; set; } = null!;
        public string Phone { get; set; } = null!;
        public string UserName { get; set; } = null!;
    }
}
