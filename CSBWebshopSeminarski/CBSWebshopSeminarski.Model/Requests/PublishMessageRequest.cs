namespace CBSWebshopSeminarski.Model.Requests
{
    public class PublishMessageRequest
    {
        public string Message { get; set; } = string.Empty;
        public string? RoutingKey { get; set; }
    }
}