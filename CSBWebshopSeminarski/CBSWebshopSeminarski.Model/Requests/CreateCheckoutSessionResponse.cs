namespace CBSWebshopSeminarski.Model.Requests
{
    public class CreateCheckoutSessionResponse
    {
        public string Url { get; set; } = string.Empty;
        public string SessionId { get; set; } = string.Empty;
        /// <summary>URL prefix used for hosted checkout success detection (server-configured).</summary>
        public string SuccessRedirectUrl { get; set; } = string.Empty;
        /// <summary>Cancel redirect URL used by Stripe (server-configured).</summary>
        public string CancelRedirectUrl { get; set; } = string.Empty;
    }
}
