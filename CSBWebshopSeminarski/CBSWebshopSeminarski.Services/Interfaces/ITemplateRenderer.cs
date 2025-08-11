namespace CBSWebshopSeminarski.Services.Interfaces
{
    public interface ITemplateRenderer
    {
        string Render(string? templateKey, string? fallbackBodyTemplate, IDictionary<string, string>? variables);
    }
}