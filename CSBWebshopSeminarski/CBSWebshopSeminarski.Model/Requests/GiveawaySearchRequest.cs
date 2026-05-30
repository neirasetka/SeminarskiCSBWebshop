namespace CBSWebshopSeminarski.Model.Requests
{
    public class GiveawaySearchRequest : PagedSearchRequest
    {
        /// <summary>active, closed, all — prazno = svi.</summary>
        public string? Status { get; set; }
    }
}
