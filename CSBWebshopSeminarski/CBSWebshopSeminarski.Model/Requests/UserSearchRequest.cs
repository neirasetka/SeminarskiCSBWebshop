namespace CBSWebshopSeminarski.Model.Requests
{
    public class UserSearchRequest : PagedSearchRequest
    {
        public string? UserName { get; set; }
    }
}
