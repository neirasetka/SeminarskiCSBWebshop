namespace CBSWebshopSeminarski.Model.Requests
{
    public class PagedSearchRequest
    {
        public int Page { get; set; } = 1;
        public int PageSize { get; set; } = 20;
    }
}
